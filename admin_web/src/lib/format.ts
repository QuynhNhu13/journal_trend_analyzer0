import { Timestamp } from 'firebase/firestore';

/**
 * Converts an unknown Firestore field into a native Date. Accepts a Firestore
 * `Timestamp`, an existing `Date`, or a millisecond number; returns null for
 * anything else (including server-timestamp placeholders that haven't resolved).
 */
export function toDateOrNull(value: unknown): Date | null {
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === 'number' && Number.isFinite(value)) return new Date(value);
  return null;
}

/** Reads a numeric field defensively, falling back to `fallback` (default 0). */
export function asNumber(value: unknown, fallback = 0): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

/** Reads a string field defensively, returning null when absent/blank. */
export function asStringOrNull(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

const DATE_TIME = new Intl.DateTimeFormat('en-GB', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
});

const DATE_ONLY = new Intl.DateTimeFormat('en-GB', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
});

/** "12/07/2026 14:30" or an em dash when null. */
export function formatDateTime(date: Date | null): string {
  return date ? DATE_TIME.format(date) : '—';
}

/** "12/07/2026" or an em dash when null. */
export function formatDate(date: Date | null): string {
  return date ? DATE_ONLY.format(date) : '—';
}

/** Human-readable byte size, e.g. "1.4 MB". Null renders as an em dash. */
export function formatBytes(bytes: number | null): string {
  if (bytes === null || !Number.isFinite(bytes)) return '—';
  if (bytes === 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.min(units.length - 1, Math.floor(Math.log(bytes) / Math.log(1024)));
  const value = bytes / 1024 ** i;
  return `${value.toFixed(i === 0 ? 0 : 1)} ${units[i]}`;
}

/** Local ISO day key, e.g. "2026-07-12". */
export function dayKey(date: Date): string {
  const y = date.getFullYear();
  const m = `${date.getMonth() + 1}`.padStart(2, '0');
  const d = `${date.getDate()}`.padStart(2, '0');
  return `${y}-${m}-${d}`;
}
