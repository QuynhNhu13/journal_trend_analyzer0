import { httpsCallable, type HttpsCallableResult } from 'firebase/functions';

import { functions } from '../lib/firebase';
import type {
  AuthUserView,
  DbDoc,
  DbField,
  DeleteUserResult,
  NotificationTarget,
  RcChange,
  RcTemplateView,
  RcValueType,
  RcVersion,
  SendResult,
  TestFcmResult,
} from '../types/models';

/** Wraps a callable so callers get a typed `(data) => Promise<Res>` function. */
function callable<Req, Res>(name: string): (data: Req) => Promise<Res> {
  const fn = httpsCallable<Req, Res>(functions, name);
  return async (data: Req) => {
    const result: HttpsCallableResult<Res> = await fn(data);
    return result.data;
  };
}

// ── Notifications ──
export interface SendNotificationInput {
  title: string;
  body: string;
  imageUrl?: string;
  data?: Record<string, string>;
  target: NotificationTarget;
}
export const sendNotification = callable<SendNotificationInput, SendResult>(
  'sendNotification',
);

export const manageTopicSubscription = callable<
  { uids: string[]; topic: string; subscribe: boolean },
  { successCount: number; failureCount: number }
>('manageTopicSubscription');

export const testFcmSend = callable<{ token: string }, TestFcmResult>('testFcmSend');

// ── Remote Config ──
export const getRemoteConfigTemplate = callable<Record<string, never>, RcTemplateView>(
  'getRemoteConfigTemplate',
);
export const publishRemoteConfig = callable<{ changes: RcChange[] }, RcTemplateView>(
  'publishRemoteConfig',
);
export const upsertRemoteConfigParam = callable<
  { name: string; valueType: RcValueType; value: string; description?: string },
  RcTemplateView
>('upsertRemoteConfigParam');
export const deleteRemoteConfigParam = callable<{ name: string }, RcTemplateView>(
  'deleteRemoteConfigParam',
);
export const listRemoteConfigVersions = callable<
  Record<string, never>,
  { versions: RcVersion[] }
>('listRemoteConfigVersions');
export const rollbackRemoteConfig = callable<{ versionNumber: number }, RcTemplateView>(
  'rollbackRemoteConfig',
);

// ── Users ──
export const listAuthUsers = callable<
  { pageToken?: string },
  { users: AuthUserView[]; nextPageToken: string | null }
>('listAuthUsers');
export const createUser = callable<
  { email: string; password: string; displayName?: string },
  { uid: string }
>('createUser');
export const updateUser = callable<
  { uid: string; displayName?: string; photoURL?: string },
  { uid: string }
>('updateUser');
export const sendPasswordReset = callable<{ email: string }, { ok: boolean }>(
  'sendPasswordReset',
);
export const setUserDisabled = callable<
  { uid: string; disabled: boolean },
  { uid: string; disabled: boolean }
>('setUserDisabled');
export const deleteUser = callable<{ uid: string }, DeleteUserResult>('deleteUser');

// ── Firestore data browser ──
export const listCollections = callable<Record<string, never>, { collections: string[] }>(
  'listCollections',
);
export const queryDocuments = callable<
  { collection: string; pageSize?: number; cursor?: string | null },
  { docs: DbDoc[]; cursor: string | null; hasMore: boolean }
>('queryDocuments');
export const upsertDocument = callable<
  { collection: string; id?: string; fields: DbField[] },
  { id: string }
>('upsertDocument');
export const deleteDocument = callable<
  { collection: string; id: string },
  { collection: string; id: string }
>('deleteDocument');

/**
 * Extracts a human-readable message from a callable error. Firebase wraps the
 * function's HttpsError message on `error.message`.
 */
export function functionErrorMessage(error: unknown, fallback: string): string {
  if (error && typeof error === 'object' && 'message' in error) {
    const message = (error as { message?: unknown }).message;
    if (typeof message === 'string' && message.length > 0) return message;
  }
  return fallback;
}
