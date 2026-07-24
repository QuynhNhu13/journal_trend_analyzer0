import {
  collection,
  getCountFromServer,
  getDocs,
  getAggregateFromServer,
  limit,
  orderBy,
  query,
  sum,
  Timestamp,
  where,
} from 'firebase/firestore';

import { db } from '../lib/firebase';
import type { DailyCount, OverviewData } from '../types/models';
import { dayKey } from '../lib/format';
import { mapReport, mapUser } from './mappers';

const DAY_MS = 24 * 60 * 60 * 1000;

/** Builds an empty 14-day series ending today (oldest first). */
function emptyLast14Days(): DailyCount[] {
  const days: DailyCount[] = [];
  const now = new Date();
  for (let i = 13; i >= 0; i -= 1) {
    const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
    days.push({
      day: dayKey(d),
      label: `${`${d.getDate()}`.padStart(2, '0')}/${`${d.getMonth() + 1}`.padStart(2, '0')}`,
      count: 0,
    });
  }
  return days;
}

/**
 * Loads every figure shown on the Overview page from Firestore only (no
 * Analytics API): four KPIs, a 14-day export series, and the most recent users
 * and reports.
 */
export async function fetchOverview(): Promise<OverviewData> {
  const usersCol = collection(db, 'users');
  const reportsCol = collection(db, 'reports');

  const cutoff7d = Timestamp.fromDate(new Date(Date.now() - 7 * DAY_MS));
  const cutoff14d = Timestamp.fromDate(new Date(Date.now() - 14 * DAY_MS));

  const [
    totalUsersSnap,
    activeUsersSnap,
    searchSumSnap,
    totalReportsSnap,
    exportsSnap,
    recentUsersSnap,
    recentReportsSnap,
  ] = await Promise.all([
    getCountFromServer(usersCol),
    getCountFromServer(query(usersCol, where('lastActiveAt', '>=', cutoff7d))),
    getAggregateFromServer(usersCol, { total: sum('searchCount') }),
    getCountFromServer(reportsCol),
    getDocs(query(reportsCol, where('createdAt', '>=', cutoff14d), orderBy('createdAt'))),
    getDocs(query(usersCol, orderBy('lastLoginAt', 'desc'), limit(5))),
    getDocs(query(reportsCol, orderBy('createdAt', 'desc'), limit(5))),
  ]);

  // Bucket exports into the 14-day series by local day.
  const series = emptyLast14Days();
  const indexByDay = new Map(series.map((d, i) => [d.day, i]));
  exportsSnap.forEach((docSnap) => {
    const report = mapReport(docSnap.id, docSnap.data());
    if (!report.createdAt) return;
    const idx = indexByDay.get(dayKey(report.createdAt));
    if (idx !== undefined) series[idx]!.count += 1;
  });

  return {
    totalUsers: totalUsersSnap.data().count,
    activeUsers7d: activeUsersSnap.data().count,
    totalSearches: searchSumSnap.data().total ?? 0,
    totalReports: totalReportsSnap.data().count,
    exportsByDay: series,
    recentUsers: recentUsersSnap.docs.map((d) => mapUser(d.id, d.data())),
    recentReports: recentReportsSnap.docs.map((d) => mapReport(d.id, d.data())),
  };
}
