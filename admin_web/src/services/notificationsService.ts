import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  limit,
  orderBy,
  query,
} from 'firebase/firestore';

import { db } from '../lib/firebase';
import type { NotificationRecord } from '../types/models';
import { mapNotification } from './mappers';

const MAX_HISTORY = 100;

/** Reads the notification send history, newest first. */
export async function fetchNotificationHistory(): Promise<NotificationRecord[]> {
  const snapshot = await getDocs(
    query(collection(db, 'notifications'), orderBy('createdAt', 'desc'), limit(MAX_HISTORY)),
  );
  return snapshot.docs.map((d) => mapNotification(d.id, d.data()));
}

/** Deletes one history record (admins only, per Firestore rules). */
export async function deleteNotificationRecord(id: string): Promise<void> {
  await deleteDoc(doc(db, 'notifications', id));
}
