import { httpsCallable, type HttpsCallableResult } from 'firebase/functions';

import { functions } from '../lib/firebase';
import type {
  AuthUserView,
  DeleteUserResult,
  NotificationTarget,
  RcChange,
  RcTemplateView,
  SendResult,
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
  target: NotificationTarget;
  data?: Record<string, string>;
}
export const sendNotification = callable<SendNotificationInput, SendResult>(
  'sendNotification',
);

// ── Remote Config ──
export const getRemoteConfigTemplate = callable<
  Record<string, never>,
  RcTemplateView
>('getRemoteConfigTemplate');

export const publishRemoteConfig = callable<
  { changes: RcChange[] },
  RcTemplateView
>('publishRemoteConfig');

// ── Users ──
export const listAuthUsers = callable<
  Record<string, never>,
  { users: AuthUserView[]; nextPageToken: string | null }
>('listAuthUsers');

export const setUserDisabled = callable<
  { uid: string; disabled: boolean },
  { uid: string; disabled: boolean }
>('setUserDisabled');

export const deleteUser = callable<{ uid: string }, DeleteUserResult>('deleteUser');

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
