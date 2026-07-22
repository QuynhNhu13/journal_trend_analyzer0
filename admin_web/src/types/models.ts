/**
 * Domain models for the admin console. Firestore Timestamps are normalized to
 * native `Date | null` by the service layer so components never touch Firebase
 * types directly.
 */

/** A row in the `users` collection (document id === uid). */
export interface AppUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  platform: string | null;
  createdAt: Date | null;
  lastLoginAt: Date | null;
  lastActiveAt: Date | null;
  searchCount: number;
  exportCount: number;
}

/** A document in the `reports` collection, optionally enriched with a file size. */
export interface ReportDoc {
  id: string;
  uid: string;
  email: string | null;
  topic: string;
  fileName: string;
  downloadUrl: string;
  createdAt: Date | null;
  /** Size in bytes from Cloud Storage; null when the file could not be matched. */
  sizeBytes: number | null;
}

/** Sort options for the users table. */
export type UserSortField = 'lastLoginAt' | 'createdAt';

/** Aggregated numbers + recent activity shown on the Overview page. */
export interface OverviewData {
  totalUsers: number;
  activeUsers7d: number;
  totalSearches: number;
  totalReports: number;
  exportsByDay: DailyCount[];
  recentUsers: AppUser[];
  recentReports: ReportDoc[];
}

/** One bar in the 14-day exports chart. */
export interface DailyCount {
  /** ISO day key (YYYY-MM-DD), local time. */
  day: string;
  /** Short label for the axis, e.g. "12/07". */
  label: string;
  count: number;
}
