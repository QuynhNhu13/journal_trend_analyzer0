import { FieldValue } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { assertAdmin } from './lib/assertAdmin';
import { db, messaging, REGION } from './lib/firebase';
import { writeAdminLog } from './lib/logs';

/** Where the notification should go. */
type NotificationTarget =
  | { type: 'all' }
  | { type: 'uids'; uids: string[] }
  | { type: 'token'; token: string };

interface SendNotificationData {
  title: string;
  body: string;
  target: NotificationTarget;
  data?: Record<string, string>;
}

/** FCM multicast accepts at most 500 tokens per call. */
const MULTICAST_CHUNK = 500;

function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}

/** Collects FCM tokens from a list of user documents. */
async function tokensForUids(uids: string[]): Promise<string[]> {
  const tokens: string[] = [];
  const refs = uids.map((uid) => db.collection('users').doc(uid));
  if (refs.length === 0) return tokens;
  const snaps = await db.getAll(...refs);
  for (const snap of snaps) {
    const token = snap.get('fcmToken');
    if (typeof token === 'string' && token.length > 0) tokens.push(token);
  }
  return tokens;
}

/** Collects FCM tokens from every user document that has one. */
async function allUserTokens(): Promise<string[]> {
  const snapshot = await db.collection('users').get();
  const tokens: string[] = [];
  snapshot.forEach((doc) => {
    const token = doc.get('fcmToken');
    if (typeof token === 'string' && token.length > 0) tokens.push(token);
  });
  return tokens;
}

async function multicast(
  tokens: string[],
  notification: { title: string; body: string },
  data?: Record<string, string>,
): Promise<{ successCount: number; failureCount: number }> {
  let successCount = 0;
  let failureCount = 0;
  for (const group of chunk(tokens, MULTICAST_CHUNK)) {
    const response = await messaging.sendEachForMulticast({
      tokens: group,
      notification,
      data,
    });
    successCount += response.successCount;
    failureCount += response.failureCount;
  }
  return { successCount, failureCount };
}

/**
 * Sends an FCM push to all users, a chosen subset (by uid), or a single manual
 * token, and records the send in the `notifications` collection.
 */
export const sendNotification = onCall<SendNotificationData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { title, body, target, data } = request.data;

    if (!title?.trim() || !body?.trim()) {
      throw new HttpsError('invalid-argument', 'Title and body are required.');
    }
    if (!target || !target.type) {
      throw new HttpsError('invalid-argument', 'A target is required.');
    }

    const notification = { title: title.trim(), body: body.trim() };

    let tokens: string[];
    let targetLabel: string;
    if (target.type === 'all') {
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

    const recipients = tokens.length;
    const { successCount, failureCount } =
      recipients > 0
        ? await multicast(tokens, notification, data)
        : { successCount: 0, failureCount: 0 };

    // Persist the send for the history table.
    const record = {
      title: notification.title,
      body: notification.body,
      targetType: target.type,
      targetLabel,
      recipients,
      successCount,
      failureCount,
      data: data ?? {},
      sentByEmail: admin.email,
      createdAt: FieldValue.serverTimestamp(),
    };
    const ref = await db.collection('notifications').add(record);

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'sendNotification',
      targetId: ref.id,
      params: { targetType: target.type, recipients },
      result: `success=${successCount}, failure=${failureCount}`,
    });

    return { id: ref.id, recipients, successCount, failureCount };
  },
);
