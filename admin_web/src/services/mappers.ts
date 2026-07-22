import type { DocumentData } from 'firebase/firestore';

import type { AppUser, ReportDoc } from '../types/models';
import { asNumber, asStringOrNull, toDateOrNull } from '../lib/format';

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
