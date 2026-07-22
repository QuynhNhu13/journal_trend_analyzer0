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

// ── Phase 3: Cloud Functions models ────────────────────────────────────────

/** A Firebase Auth user reconciled with its Firestore profile (listAuthUsers). */
export interface AuthUserView {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  disabled: boolean;
  isAdmin: boolean;
  hasProfile: boolean;
  creationTime: string | null;
  lastSignInTime: string | null;
  searchCount: number;
  exportCount: number;
}

/** Summary returned by deleteUser. */
export interface DeleteUserResult {
  uid: string;
  authDeleted: boolean;
  profileDeleted: boolean;
  reportsDeleted: number;
  filesDeleted: number;
}

/** Where a push notification is sent. */
export type NotificationTarget =
  | { type: 'all' }
  | { type: 'uids'; uids: string[] }
  | { type: 'token'; token: string };

export type NotificationTargetType = NotificationTarget['type'];

/** Result of a send. */
export interface SendResult {
  id: string;
  recipients: number;
  successCount: number;
  failureCount: number;
}

/** A row in the `notifications` history collection. */
export interface NotificationRecord {
  id: string;
  title: string;
  body: string;
  targetType: NotificationTargetType;
  targetLabel: string;
  recipients: number;
  successCount: number;
  failureCount: number;
  data: Record<string, string>;
  sentByEmail: string | null;
  createdAt: Date | null;
}

/** Remote Config value types (mirrors the Admin SDK's ParameterValueType). */
export type RcValueType =
  | 'STRING'
  | 'BOOLEAN'
  | 'NUMBER'
  | 'JSON'
  | 'PARAMETER_VALUE_TYPE_UNSPECIFIED';

/** A flattened Remote Config parameter. */
export interface RcParam {
  name: string;
  valueType: RcValueType;
  value: string | null;
  description: string;
}

/** The Remote Config template view returned by the functions. */
export interface RcTemplateView {
  parameters: RcParam[];
  version: { updateTime: string | null; updateUserEmail: string | null } | null;
}

/** A single pending change applied in one atomic publish. */
export type RcChange =
  | { op: 'set'; name: string; valueType: RcValueType; value: string; description?: string }
  | { op: 'delete'; name: string };

/** A row in the `admin_logs` audit collection. */
export interface AdminLog {
  id: string;
  actorEmail: string | null;
  action: string;
  targetId: string | null;
  params: Record<string, unknown>;
  result: string | null;
  createdAt: Date | null;
}
