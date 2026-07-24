import { FieldValue } from 'firebase-admin/firestore';
import type { Notification } from 'firebase-admin/messaging';
import * as logger from 'firebase-functions/logger';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { assertAdmin } from './lib/assertAdmin';
import { db, messaging, REGION } from './lib/firebase';
import { writeAdminLog } from './lib/logs';
import { wrap } from './lib/wrap';

/** Last 12 chars of a token — enough to identify it in logs without leaking it. */
function tokenSuffix(token: string): string {
  return `…${token.slice(-12)}`;
}

/**
 * FCM error shape. `firebase-admin` throws `FirebaseMessagingError` whose real
 * cause is on `.code` (e.g. "messaging/invalid-payload") and `.message`; some
 * versions nest it under `.errorInfo`. Read both so logs show the true reason.
 */
interface FcmError {
  name?: string;
  code?: string;
  message?: string;
  stack?: string;
  errorInfo?: { code?: string; message?: string };
}

function fcmCode(e: FcmError): string {
  return e.errorInfo?.code ?? e.code ?? e.name ?? 'unknown';
}

function fcmMessage(e: FcmError): string {
  return e.errorInfo?.message ?? e.message ?? '';
}

/**
 * FCM topic names must NOT carry the `/topics/` prefix and must match
 * `[a-zA-Z0-9-_.~%]+` (no spaces). Strip the prefix, trim, and validate — throw
 * a clear client error instead of letting FCM reject with "Malformed topic name".
 */
const TOPIC_REGEX = /^[a-zA-Z0-9-_.~%]+$/;

function normalizeTopic(raw: string): string {
  let topic = raw.trim();
  if (topic.startsWith('/topics/')) topic = topic.slice('/topics/'.length).trim();
  if (!topic || !TOPIC_REGEX.test(topic)) {
    throw new HttpsError(
      'invalid-argument',
      `Tên topic không hợp lệ: "${raw}". Chỉ cho phép chữ, số và các ký tự - _ . ~ % (không có khoảng trắng).`,
    );
  }
  return topic;
}

/**
 * Coerces arbitrary input into an FCM-safe string map: every value becomes a
 * string via String(v); null/undefined values and blank keys/values are dropped.
 * Returns `undefined` when nothing usable remains — the caller then omits the
 * `data` field entirely (FCM rejects `data: null` / non-string values).
 */
function sanitizeData(input: unknown): Record<string, string> | undefined {
  if (!input || typeof input !== 'object' || Array.isArray(input)) return undefined;
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(input as Record<string, unknown>)) {
    if (!key.trim()) continue;
    if (value === null || value === undefined) continue;
    const str = String(value);
    if (str.length === 0) continue;
    out[key.trim()] = str;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

/** Builds the notification block, only attaching imageUrl when it's a real URL. */
function buildNotification(title: string, body: string, imageUrl?: string): Notification {
  const notification: Notification = { title: title.trim(), body: body.trim() };
  const img = imageUrl?.trim();
  if (img) notification.imageUrl = img;
  return notification;
}

/** Any single valid FCM send target. */
type SendTarget = { token: string } | { topic: string } | { tokens: string[] };

/**
 * THE single message builder used by every branch (token / topic / multicast).
 * It attaches `data` ONLY when there is a non-empty sanitized map, so no branch
 * can ever send `data: null`/`undefined` — the root cause of the invalid-payload
 * and "data must be a non-null object" errors.
 */
function buildMessage<T extends SendTarget>(
  target: T,
  notification: Notification,
  data?: Record<string, string>,
): T & { notification: Notification; data?: Record<string, string> } {
  const message = { ...target, notification } as T & {
    notification: Notification;
    data?: Record<string, string>;
  };
  if (data) message.data = data;
  return message;
}

/** Redacted payload for logs — shows exactly what was sent, minus real tokens. */
function redactPayload(
  notification: Notification,
  data: Record<string, string> | undefined,
  targetLabel: string,
): Record<string, unknown> {
  return { notification, data: data ?? null, target: targetLabel };
}

/** Where the notification should go. */
type NotificationTarget =
  | { type: 'topic'; topic: string } // "all" or a custom topic name
  | { type: 'uids'; uids: string[] }
  | { type: 'token'; token: string };

interface SendNotificationData {
  title: string;
  body: string;
  imageUrl?: string;
  data?: Record<string, string>;
  target: NotificationTarget;
}

/** FCM multicast accepts at most 500 tokens per call. */
const MULTICAST_CHUNK = 500;

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

async function tokensForUids(uids: string[]): Promise<string[]> {
  if (uids.length === 0) return [];
  const snaps = await db.getAll(...uids.map((uid) => db.collection('users').doc(uid)));
  const tokens: string[] = [];
  for (const snap of snaps) {
    const token = snap.get('fcmToken');
    if (typeof token === 'string' && token.length > 0) tokens.push(token);
  }
  return tokens;
}

async function allUserTokens(): Promise<string[]> {
  const snapshot = await db.collection('users').get();
  const tokens: string[] = [];
  snapshot.forEach((doc) => {
    const token = doc.get('fcmToken');
    if (typeof token === 'string' && token.length > 0) tokens.push(token);
  });
  return tokens;
}

/** One failed token with its FCM error code — the key diagnostic. */
interface TokenFailure {
  tokenSuffix: string;
  code: string;
  message: string;
}

interface MulticastOutcome {
  successCount: number;
  failureCount: number;
  failures: TokenFailure[];
}

async function multicast(
  tokens: string[],
  notification: Notification,
  data?: Record<string, string>,
): Promise<MulticastOutcome> {
  let successCount = 0;
  let failureCount = 0;
  const failures: TokenFailure[] = [];

  for (const group of chunk(tokens, MULTICAST_CHUNK)) {
    // Built via the shared builder → `data` is present ONLY when non-empty.
    const message = buildMessage({ tokens: group }, notification, data);

    // sendEachForMulticast throws ONLY on systemic errors (bad payload, auth);
    // per-token failures come back on response.responses[i].error — capture both.
    let response;
    try {
      response = await messaging.sendEachForMulticast(message);
    } catch (error) {
      const e = error as FcmError;
      logger.error('[send (multicast)] sendEachForMulticast threw', {
        code: fcmCode(e),
        message: fcmMessage(e),
        stack: e.stack,
        payload: redactPayload(notification, data, `${group.length} token(s)`),
      });
      throw new HttpsError('internal', `FCM send failed: ${fcmCode(e)}: ${fcmMessage(e)}`);
    }

    successCount += response.successCount;
    failureCount += response.failureCount;
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const e = (r.error ?? {}) as FcmError;
        const code = fcmCode(e);
        const msg = fcmMessage(e);
        const suffix = tokenSuffix(group[i] as string);
        failures.push({ tokenSuffix: suffix, code, message: msg });
        logger.error('[send (multicast)] token failed', { code, message: msg, token: suffix });
      }
    });
  }

  return { successCount, failureCount, failures };
}

/**
 * Sends an FCM push. Targets:
 *  - topic "all" → fan out to every user's token (reliable without app-side
 *    subscription); any other topic → native topic send.
 *  - uids  → the selected users' tokens (multicast).
 *  - token → a single manual device token.
 */
export const sendNotification = onCall<SendNotificationData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { title, body, imageUrl, data: rawData, target } = request.data;

    // title/body are REQUIRED non-empty strings — validate up-front with a clear
    // client error rather than letting FCM reject the payload later.
    if (!title?.trim() || !body?.trim()) {
      throw new HttpsError('invalid-argument', 'Title and body are required.');
    }
    if (!target?.type) {
      throw new HttpsError('invalid-argument', 'A target is required.');
    }

    const notification = buildNotification(title, body, imageUrl);
    // Sanitize ONCE here; every branch reuses this. `undefined` ⇒ no data field.
    const data = sanitizeData(rawData);

    let recipients = 0;
    let successCount = 0;
    let failureCount = 0;
    let failures: TokenFailure[] = [];
    let targetLabel = '';

    if (target.type === 'topic' && target.topic !== 'all') {
      const topic = normalizeTopic(target.topic);
      targetLabel = `Topic: ${topic}`;
      const message = buildMessage({ topic }, notification, data);
      try {
        await messaging.send(message);
      } catch (error) {
        const e = error as FcmError;
        logger.error('[send (topic)] failed', {
          code: fcmCode(e),
          message: fcmMessage(e),
          stack: e.stack,
          payload: redactPayload(notification, data, targetLabel),
        });
        throw new HttpsError('internal', `Gửi topic thất bại: ${fcmCode(e)}: ${fcmMessage(e)}`);
      }
      recipients = -1; // unknown for a topic broadcast
      successCount = 1;
    } else {
      let tokens: string[];
      if (target.type === 'topic') {
        tokens = await allUserTokens();
        targetLabel = 'All users';
      } else if (target.type === 'uids') {
        if (!Array.isArray(target.uids) || target.uids.length === 0) {
          throw new HttpsError('invalid-argument', 'Select at least one user.');
        }
        tokens = await tokensForUids(target.uids);
        targetLabel = `${target.uids.length} selected user(s)`;
      } else {
        if (!target.token?.trim()) {
          throw new HttpsError('invalid-argument', 'A device token is required.');
        }
        tokens = [target.token.trim()];
        targetLabel = 'Manual token';
      }
      recipients = tokens.length;
      if (tokens.length > 0) {
        const outcome = await multicast(tokens, notification, data);
        successCount = outcome.successCount;
        failureCount = outcome.failureCount;
        failures = outcome.failures;
      }
    }

    const ref = await db.collection('notifications').add({
      title: notification.title,
      body: notification.body,
      imageUrl: notification.imageUrl ?? null,
      targetType: target.type,
      targetLabel,
      recipients,
      successCount,
      failureCount,
      failures: failures.slice(0, 50),
      data: data ?? {},
      sentByEmail: admin.email,
      createdAt: FieldValue.serverTimestamp(),
    });

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'sendNotification',
      targetId: ref.id,
      params: { targetType: target.type, recipients },
      result: `success=${successCount}, failure=${failureCount}`,
    });

    return { id: ref.id, recipients, successCount, failureCount, failures };
  },
);

/**
 * Diagnostic: sends a minimal push to a single token and returns the raw result
 * or the raw error (name / code / message) WITHOUT throwing, so the admin can
 * see exactly why a token fails (e.g. messaging/registration-token-not-registered,
 * messaging/mismatched-credential, messaging/invalid-argument).
 */
export const testFcmSend = onCall<{ token: string }>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const token = request.data?.token?.trim();
    if (!token) throw new HttpsError('invalid-argument', 'A device token is required.');

    try {
      const messageId = await messaging.send({
        token,
        notification: { title: 'FCM test', body: 'Diagnostic message from the admin console.' },
      });
      logger.info('[testFcmSend] ok', { messageId, token: tokenSuffix(token) });
      await writeAdminLog({
        actorEmail: admin.email,
        action: 'testFcmSend',
        targetId: tokenSuffix(token),
        result: 'ok',
      });
      return { ok: true, messageId, name: null, code: null, message: null };
    } catch (error) {
      const e = error as { name?: string; code?: string; message?: string; stack?: string };
      logger.error('[testFcmSend] failed', {
        name: e.name,
        code: e.code,
        message: e.message,
        stack: e.stack,
        token: tokenSuffix(token),
      });
      await writeAdminLog({
        actorEmail: admin.email,
        action: 'testFcmSend',
        targetId: tokenSuffix(token),
        result: `error: ${e.code ?? e.name ?? 'unknown'}`,
      });
      return {
        ok: false,
        messageId: null,
        name: e.name ?? null,
        code: e.code ?? null,
        message: e.message ?? String(error),
      };
    }
  },
);

interface ManageTopicData {
  uids: string[];
  topic: string;
  subscribe: boolean;
}

/**
 * Subscribes or unsubscribes the FCM tokens of the given users to/from a topic,
 * so an admin can build audience groups (e.g. "beta-testers").
 */
export const manageTopicSubscription = onCall<ManageTopicData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { uids, topic: rawTopic, subscribe } = request.data;
    if (!rawTopic?.trim()) throw new HttpsError('invalid-argument', 'A topic is required.');
    if (!Array.isArray(uids) || uids.length === 0) {
      throw new HttpsError('invalid-argument', 'Select at least one user.');
    }
    const topic = normalizeTopic(rawTopic);

    const tokens = await tokensForUids(uids);
    if (tokens.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    const response = await wrap('manageTopicSubscription', () =>
      subscribe
        ? messaging.subscribeToTopic(tokens, topic)
        : messaging.unsubscribeFromTopic(tokens, topic),
    );

    await writeAdminLog({
      actorEmail: admin.email,
      action: subscribe ? 'subscribeTopic' : 'unsubscribeTopic',
      targetId: topic,
      params: { count: tokens.length },
      result: `success=${response.successCount}`,
    });

    return { successCount: response.successCount, failureCount: response.failureCount };
  },
);
