import type { DocumentData } from 'firebase/firestore';

import type {
  AdminLog,
  AppUser,
  NotificationRecord,
  NotificationTargetType,
  ReportDoc,
} from '../types/models';
import { asNumber, asStringOrNull, toDateOrNull } from '../lib/format';

/** Narrows an unknown field to a string-keyed record (or empty). */
function asRecord(value: unknown): Record<string, string> {
  if (value && typeof value === 'object') {
    return value as Record<string, string>;
  }
  return {};
}

/** Maps a Firestore `users/{uid}` document into an AppUser. */
export function mapUser(id: string, data: DocumentData): AppUser {
  return {
    uid: asStringOrNull(data.uid) ?? id,
    email: asStringOrNull(data.email),
    displayName: asStringOrNull(data.displayName),
    photoUrl: asStringOrNull(data.photoUrl),
    platform: asStringOrNull(data.platform),
    createdAt: toDateOrNull(data.createdAt),
    lastLoginAt: toDateOrNull(data.lastLoginAt),
    lastActiveAt: toDateOrNull(data.lastActiveAt),
    searchCount: asNumber(data.searchCount),
    exportCount: asNumber(data.exportCount),
  };
}

/** Maps a Firestore `reports/{id}` document into a ReportDoc (size added later). */
export function mapReport(id: string, data: DocumentData): ReportDoc {
  return {
    id,
    uid: asStringOrNull(data.uid) ?? '',
    email: asStringOrNull(data.email),
    topic: asStringOrNull(data.topic) ?? '—',
    fileName: asStringOrNull(data.fileName) ?? '',
    downloadUrl: asStringOrNull(data.downloadUrl) ?? '',
    createdAt: toDateOrNull(data.createdAt),
    sizeBytes: null,
  };
}

/** Maps a Firestore `notifications/{id}` document into a NotificationRecord. */
export function mapNotification(id: string, data: DocumentData): NotificationRecord {
  const targetType = (asStringOrNull(data.targetType) ?? 'all') as NotificationTargetType;
  return {
    id,
    title: asStringOrNull(data.title) ?? '—',
    body: asStringOrNull(data.body) ?? '',
    targetType,
    targetLabel: asStringOrNull(data.targetLabel) ?? '—',
    recipients: asNumber(data.recipients),
    successCount: asNumber(data.successCount),
    failureCount: asNumber(data.failureCount),
    data: asRecord(data.data),
    sentByEmail: asStringOrNull(data.sentByEmail),
    createdAt: toDateOrNull(data.createdAt),
  };
}

/** Maps a Firestore `admin_logs/{id}` document into an AdminLog. */
export function mapAdminLog(id: string, data: DocumentData): AdminLog {
  return {
    id,
    actorEmail: asStringOrNull(data.actorEmail),
    action: asStringOrNull(data.action) ?? '—',
    targetId: asStringOrNull(data.targetId),
    params: (data.params && typeof data.params === 'object'
      ? (data.params as Record<string, unknown>)
      : {}),
    result: asStringOrNull(data.result),
    createdAt: toDateOrNull(data.createdAt),
  };
}
