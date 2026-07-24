import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  where,
  type DocumentData,
  type QueryConstraint,
  type QueryDocumentSnapshot,
} from 'firebase/firestore';

import { db } from '../lib/firebase';
import type { AppUser, ReportDoc, UserSortField } from '../types/models';
import { mapReport, mapUser } from './mappers';

export type UserCursor = QueryDocumentSnapshot<DocumentData>;

export interface UsersPage {
  users: AppUser[];
  cursor: UserCursor | null;
  hasMore: boolean;
}

/**
 * Fetches one page of users ordered by `sortBy` (descending), using
 * `limit` + `startAfter` for lazy loading. Pass the previous page's `cursor` to
 * load the next page.
 */
export async function fetchUsersPage(options: {
  sortBy: UserSortField;
  pageSize: number;
  cursor?: UserCursor | null;
}): Promise<UsersPage> {
  const { sortBy, pageSize, cursor } = options;
  const constraints: QueryConstraint[] = [orderBy(sortBy, 'desc')];
  if (cursor) constraints.push(startAfter(cursor));
  constraints.push(limit(pageSize));

  const snapshot = await getDocs(query(collection(db, 'users'), ...constraints));
  const users = snapshot.docs.map((d) => mapUser(d.id, d.data()));
  const lastDoc = snapshot.docs[snapshot.docs.length - 1] ?? null;

  return {
    users,
    cursor: lastDoc,
    hasMore: snapshot.size === pageSize,
  };
}

/** Loads a single user document by uid. */
export async function fetchUserById(uid: string): Promise<AppUser | null> {
  const snap = await getDoc(doc(db, 'users', uid));
  return snap.exists() ? mapUser(snap.id, snap.data()) : null;
}

/**
 * Loads all reports a given user exported. Filtered server-side by `uid`, then
 * sorted client-side by date so no composite Firestore index is required.
 */
export async function fetchReportsByUser(uid: string): Promise<ReportDoc[]> {
  const snapshot = await getDocs(
    query(collection(db, 'reports'), where('uid', '==', uid)),
  );
  const reports = snapshot.docs.map((d) => mapReport(d.id, d.data()));
  reports.sort(
    (a, b) => (b.createdAt?.getTime() ?? 0) - (a.createdAt?.getTime() ?? 0),
  );
  return reports;
}
