import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  limit,
  orderBy,
  query,
} from 'firebase/firestore';
import {
  deleteObject,
  getMetadata,
  listAll,
  ref,
} from 'firebase/storage';

import { db, storage } from '../lib/firebase';
import type { ReportDoc } from '../types/models';
import { mapReport } from './mappers';

/** Storage folder the Flutter app uploads exported PDFs into. */
const REPORTS_FOLDER = 'reports';

/** Safety cap so a huge collection can't be pulled in a single read. */
const MAX_REPORTS = 500;

export interface StorageEntry {
  fileName: string;
  sizeBytes: number;
}

export interface ReportsResult {
  reports: ReportDoc[];
  /** Total bytes across ALL files in the Storage `reports/` folder. */
  totalStorageBytes: number;
  /** True when Storage could not be read (e.g. rules) — sizes are unavailable. */
  storageUnavailable: boolean;
}

/** Reads report documents from Firestore, newest first. */
async function fetchReportDocs(): Promise<ReportDoc[]> {
  const snapshot = await getDocs(
    query(collection(db, 'reports'), orderBy('createdAt', 'desc'), limit(MAX_REPORTS)),
  );
  return snapshot.docs.map((d) => mapReport(d.id, d.data()));
}

/** Lists every file in Storage `reports/` with its size. */
async function fetchStorageEntries(): Promise<StorageEntry[]> {
  const folder = ref(storage, REPORTS_FOLDER);
  const listing = await listAll(folder);
  return Promise.all(
    listing.items.map(async (item) => {
      const meta = await getMetadata(item);
      return { fileName: item.name, sizeBytes: meta.size };
    }),
  );
}

/**
 * Loads reports from Firestore (rich metadata) and reconciles them with the
 * Storage folder to attach file sizes and compute total usage. If Storage is
 * unreachable, reports are still returned (without sizes).
 */
export async function fetchReports(): Promise<ReportsResult> {
  const reports = await fetchReportDocs();

  let storageEntries: StorageEntry[] = [];
  let storageUnavailable = false;
  try {
    storageEntries = await fetchStorageEntries();
  } catch {
    storageUnavailable = true;
  }

  const sizeByName = new Map(storageEntries.map((e) => [e.fileName, e.sizeBytes]));
  const enriched = reports.map((r) => ({
    ...r,
    sizeBytes: sizeByName.get(r.fileName) ?? null,
  }));

  const totalStorageBytes = storageEntries.reduce((sum, e) => sum + e.sizeBytes, 0);

  return { reports: enriched, totalStorageBytes, storageUnavailable };
}

/**
 * Deletes a report everywhere: the Storage object first, then the Firestore
 * document. A missing Storage object is tolerated (already gone) so the
 * Firestore document can still be cleaned up.
 */
export async function deleteReport(report: ReportDoc): Promise<void> {
  if (report.fileName) {
    try {
      await deleteObject(ref(storage, `${REPORTS_FOLDER}/${report.fileName}`));
    } catch (error: unknown) {
      const code = (error as { code?: string }).code;
      if (code !== 'storage/object-not-found') throw error;
    }
  }
  await deleteDoc(doc(db, 'reports', report.id));
}
