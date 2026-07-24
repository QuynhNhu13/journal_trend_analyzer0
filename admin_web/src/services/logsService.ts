import {
  collection,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  type DocumentData,
  type QueryConstraint,
  type QueryDocumentSnapshot,
} from 'firebase/firestore';

import { db } from '../lib/firebase';
import type { AdminLog } from '../types/models';
import { mapAdminLog } from './mappers';

export type LogCursor = QueryDocumentSnapshot<DocumentData>;

export interface LogsPage {
  logs: AdminLog[];
  cursor: LogCursor | null;
  hasMore: boolean;
}

/**
 * Fetches one page of audit logs (newest first) via limit + startAfter. Filtering
 * by action is done client-side to avoid a composite index (equality + orderBy).
 */
export async function fetchLogsPage(options: {
  pageSize: number;
  cursor?: LogCursor | null;
}): Promise<LogsPage> {
  const { pageSize, cursor } = options;
  const constraints: QueryConstraint[] = [orderBy('createdAt', 'desc')];
  if (cursor) constraints.push(startAfter(cursor));
  constraints.push(limit(pageSize));

  const snapshot = await getDocs(query(collection(db, 'admin_logs'), ...constraints));
  const logs = snapshot.docs.map((d) => mapAdminLog(d.id, d.data()));
  const lastDoc = snapshot.docs[snapshot.docs.length - 1] ?? null;

  return { logs, cursor: lastDoc, hasMore: snapshot.size === pageSize };
}
