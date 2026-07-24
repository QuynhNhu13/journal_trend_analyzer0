import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react';
import { sendPasswordResetEmail } from 'firebase/auth';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { Avatar } from '../components/ui/Avatar';
import { Badge } from '../components/ui/Badge';
import { Icon } from '../components/ui/Icon';
import { Modal } from '../components/ui/Modal';
import { Spinner } from '../components/ui/Spinner';
import { TableSkeleton } from '../components/ui/Skeleton';
import { RowActions } from '../components/ui/RowActions';
import { Pagination } from '../components/ui/Pagination';
import { EmptyState, ErrorState } from '../components/ui/StateView';
import { useToast } from '../components/ui/Toast';
import { useAuth } from '../context/AuthContext';
import { auth } from '../lib/firebase';
import { strings } from '../constants/strings';
import type { AppUser, AuthUserView } from '../types/models';
import {
  createUser,
  deleteUser,
  functionErrorMessage,
  listAuthUsers,
  sendPasswordReset,
  setUserDisabled,
  updateUser,
} from '../services/functionsService';
import { fetchUsersPage } from '../services/usersService';

/**
 * Maps a Firestore `users` profile onto the AuthUserView shape so the table can
 * render it in fallback mode (when Authentication listing is unavailable).
 * Fields that only exist in Auth (disabled, isAdmin) default conservatively.
 */
function profileToAuthView(u: AppUser): AuthUserView {
  return {
    uid: u.uid,
    email: u.email,
    displayName: u.displayName,
    photoUrl: u.photoUrl,
    disabled: false,
    emailVerified: false,
    providers: [],
    isAdmin: false,
    hasProfile: true,
    creationTime: u.createdAt ? u.createdAt.toISOString() : null,
    lastSignInTime: u.lastLoginAt ? u.lastLoginAt.toISOString() : null,
    lastActiveAt: u.lastActiveAt ? u.lastActiveAt.toISOString() : null,
    searchCount: u.searchCount,
    exportCount: u.exportCount,
    hasFcmToken: false,
    fcmTokenUpdatedAt: null,
  };
}

/** Maps a provider id to a short label. */
function providerLabel(providers: string[]): string {
  if (providers.includes('google.com')) return strings.usersAdmin.providerGoogle;
  if (providers.includes('password')) return strings.usersAdmin.providerEmail;
  return providers[0] ?? '—';
}

function formatIso(value: string | null): string {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '—' : date.toLocaleString('en-GB');
}

/** Short date only (dd/mm/yyyy) so the column stays narrow. */
function formatDate(value: string | null): string {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '—' : date.toLocaleDateString('en-GB');
}

/** How many rows to show per page in the table. */
const PAGE_SIZE = 10;

type Dialog =
  | { kind: 'lock' | 'unlock' | 'delete' | 'edit'; user: AuthUserView }
  | { kind: 'create' }
  | { kind: 'bulk-lock' }
  | null;

export function UsersPage() {
  const { showToast } = useToast();
  const { user: currentUser } = useAuth();

  const [users, setUsers] = useState<AuthUserView[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [usingFallback, setUsingFallback] = useState(false);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<Set<string>>(new Set());

  const [dialog, setDialog] = useState<Dialog>(null);
  const [busy, setBusy] = useState(false);
  const [confirmEmail, setConfirmEmail] = useState('');

  // Create / edit form fields.
  const [fEmail, setFEmail] = useState('');
  const [fPassword, setFPassword] = useState('');
  const [fName, setFName] = useState('');
  const [fPhoto, setFPhoto] = useState('');

  // Fallback: read the Firestore `users` collection directly (same source the
  // Overview uses) and render it in the table. Returns true if it produced rows.
  const loadFromFirestore = useCallback(async (): Promise<boolean> => {
    try {
      const page = await fetchUsersPage({ sortBy: 'lastLoginAt', pageSize: 500 });
      setUsers(page.users.map(profileToAuthView));
      setSelected(new Set());
      setUsingFallback(true);
      return true;
    } catch (err) {
      console.error('[Users] Firestore fallback failed:', err);
      return false;
    }
  }, []);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    setUsingFallback(false);
    try {
      // Walk every Auth page so the table always holds the COMPLETE list of
      // accounts, then paginate on the client. This guarantees no account is
      // ever hidden behind a server page boundary.
      const all: AuthUserView[] = [];
      let token: string | undefined;
      do {
        const result = await listAuthUsers(token ? { pageToken: token } : {});
        all.push(...(result?.users ?? []));
        token = result?.nextPageToken ?? undefined;
      } while (token);

      // Defensive de-dup by uid so a duplicate React key can never collapse rows.
      const unique = Array.from(new Map(all.map((u) => [u.uid, u])).values());
      if (unique.length > 0) {
        setUsers(unique);
        setSelected(new Set());
      } else {
        // Function succeeded but returned nothing — never leave the table
        // silently empty; fall back to Firestore profiles.
        console.warn('[Users] listAuthUsers returned 0 accounts — using Firestore fallback');
        await loadFromFirestore();
      }
    } catch (err) {
      console.error('[Users] listAuthUsers failed:', err);
      const recovered = await loadFromFirestore();
      if (!recovered) setError(functionErrorMessage(err, strings.usersAdmin.errorMessage));
    } finally {
      setLoading(false);
    }
  }, [loadFromFirestore]);

  useEffect(() => {
    void load();
  }, [load]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    const base = !q
      ? users
      : users.filter(
          (u) =>
            (u.displayName ?? '').toLowerCase().includes(q) ||
            (u.email ?? '').toLowerCase().includes(q),
        );
    // Most recently signed-in first, so new/active users are always on top
    // (never buried at the bottom of the list).
    const ts = (value: string | null) => (value ? new Date(value).getTime() : 0);
    return [...base].sort((a, b) => ts(b.lastSignInTime) - ts(a.lastSignInTime));
  }, [users, search]);

  // Client-side pagination (PAGE_SIZE per page). `pageSafe` clamps the current
  // page in case the list shrank (delete, new search) below the old page index.
  const totalPages = Math.max(1, Math.ceil(filtered.length / PAGE_SIZE));
  const pageSafe = Math.min(page, totalPages);
  const pageItems = useMemo(
    () => filtered.slice((pageSafe - 1) * PAGE_SIZE, pageSafe * PAGE_SIZE),
    [filtered, pageSafe],
  );

  // Reset to the first page whenever the search term or the data set changes.
  useEffect(() => {
    setPage(1);
  }, [search, users]);

  const closeDialog = () => {
    if (busy) return;
    setDialog(null);
    setConfirmEmail('');
  };

  const toggleSelect = (uid: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(uid)) next.delete(uid);
      else next.add(uid);
      return next;
    });
  };

  const openCreate = () => {
    setFEmail('');
    setFPassword('');
    setFName('');
    setDialog({ kind: 'create' });
  };

  const openEdit = (user: AuthUserView) => {
    setFName(user.displayName ?? '');
    setFPhoto(user.photoUrl ?? '');
    setDialog({ kind: 'edit', user });
  };

  const handleCreate = async () => {
    setBusy(true);
    try {
      await createUser({
        email: fEmail.trim(),
        password: fPassword,
        displayName: fName.trim() || undefined,
      });
      showToast(strings.usersAdmin.createdToast);
      setDialog(null);
      await load();
    } catch (err) {
      showToast(functionErrorMessage(err, strings.usersAdmin.createError), 'error');
    } finally {
      setBusy(false);
    }
  };

  const handleEdit = async (target: AuthUserView) => {
    setBusy(true);
    try {
      await updateUser({
        uid: target.uid,
        displayName: fName.trim() || undefined,
        photoURL: fPhoto.trim() || undefined,
      });
      setUsers((prev) =>
        prev.map((u) =>
          u.uid === target.uid
            ? { ...u, displayName: fName.trim() || null, photoUrl: fPhoto.trim() || null }
            : u,
        ),
      );
      showToast(strings.usersAdmin.updatedToast);
      setDialog(null);
    } catch (err) {
      showToast(functionErrorMessage(err, strings.usersAdmin.updateError), 'error');
    } finally {
      setBusy(false);
    }
  };

  const handleReset = async (target: AuthUserView) => {
    if (!target.email) return;
    try {
      await sendPasswordReset({ email: target.email });
      await sendPasswordResetEmail(auth, target.email);
      showToast(strings.usersAdmin.resetSent);
    } catch (err) {
      showToast(functionErrorMessage(err, strings.usersAdmin.resetError), 'error');
    }
  };

  const handleToggleDisabled = async (target: AuthUserView, disabled: boolean) => {
    setBusy(true);
    try {
      await setUserDisabled({ uid: target.uid, disabled });
      setUsers((prev) => prev.map((u) => (u.uid === target.uid ? { ...u, disabled } : u)));
      showToast(disabled ? strings.usersAdmin.lockedToast : strings.usersAdmin.unlockedToast);
      setDialog(null);
    } catch (err) {
      showToast(functionErrorMessage(err, strings.usersAdmin.actionError), 'error');
    } finally {
      setBusy(false);
    }
  };

  const handleBulkLock = async () => {
    const targets = users.filter((u) => selected.has(u.uid) && u.uid !== currentUser?.uid);
    setBusy(true);
    try {
      for (const target of targets) {
        await setUserDisabled({ uid: target.uid, disabled: true });
      }
      const lockedIds = new Set(targets.map((t) => t.uid));
      setUsers((prev) => prev.map((u) => (lockedIds.has(u.uid) ? { ...u, disabled: true } : u)));
      showToast(strings.usersAdmin.bulkLockedToast(targets.length));
      setSelected(new Set());
      setDialog(null);
    } catch (err) {
      showToast(functionErrorMessage(err, strings.usersAdmin.actionError), 'error');
    } finally {
      setBusy(false);
    }
  };

  const handleDelete = async (target: AuthUserView) => {
    setBusy(true);
    try {
      const result = await deleteUser({ uid: target.uid });
      setUsers((prev) => prev.filter((u) => u.uid !== target.uid));
      showToast(strings.usersAdmin.deleteSummary(result.reportsDeleted, result.filesDeleted));
      setDialog(null);
      setConfirmEmail('');
    } catch (err) {
      showToast(functionErrorMessage(err, strings.usersAdmin.deleteError), 'error');
    } finally {
      setBusy(false);
    }
  };

  const selectableCount = selected.size;

  return (
    <div>
      <PageHeader title={strings.pages.users.title} subtitle={strings.pages.users.subtitle} />

      <div className="px-4 py-6 sm:px-8 sm:py-8">
        <Card className="!p-0">
          {usingFallback ? (
            <div className="flex items-start gap-2 border-b border-hairline bg-warning/10 px-4 py-2.5 text-sm text-body">
              <Icon name="alert" className="mt-0.5 h-4 w-4 shrink-0 text-warning" />
              {strings.usersAdmin.fallbackNotice}
            </div>
          ) : null}
          <div className="flex flex-col gap-3 border-b border-hairline p-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative sm:w-72">
              <Icon
                name="users"
                className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-faint"
              />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder={strings.usersAdmin.searchPlaceholder}
                className="w-full rounded-md border border-hairline bg-canvas py-2.5 pl-9 pr-3 text-sm text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
              />
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {selectableCount > 0 ? (
                <button
                  type="button"
                  onClick={() => setDialog({ kind: 'bulk-lock' })}
                  className="flex items-center gap-2 rounded-md border border-danger/40 px-3 py-2 text-sm font-semibold text-danger transition hover:bg-danger/5"
                >
                  <Icon name="lock" className="h-4 w-4" />
                  {strings.usersAdmin.lockSelected} ({selectableCount})
                </button>
              ) : null}
              <button
                type="button"
                onClick={() => void load()}
                className="flex items-center gap-2 rounded-md border border-hairline px-3 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand"
              >
                <Icon name="refresh" className="h-4 w-4" />
                {strings.usersAdmin.reload}
              </button>
              <button
                type="button"
                onClick={openCreate}
                className="flex items-center gap-2 rounded-md bg-brand px-3 py-2 text-sm font-bold text-white transition hover:bg-brand-bright"
              >
                <Icon name="plus" className="h-4 w-4" />
                {strings.usersAdmin.newUser}
              </button>
            </div>
          </div>

          {loading ? (
            <TableSkeleton rows={6} columns={5} />
          ) : error ? (
            <ErrorState message={error} onRetry={() => void load()} />
          ) : users.length === 0 ? (
            <EmptyState
              icon="users"
              title={strings.usersAdmin.emptyTitle}
              message={strings.usersAdmin.emptyMessage}
            />
          ) : filtered.length === 0 ? (
            <EmptyState icon="users" title={strings.usersAdmin.noMatch} />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full table-auto border-collapse text-left">
                <thead>
                  <tr className="border-b border-hairline bg-subtle text-label uppercase text-muted">
                    <th className="w-10 px-4 py-3" />
                    <th className="px-4 py-3">{strings.usersAdmin.col.user}</th>
                    <th className="px-4 py-3">{strings.usersAdmin.col.status}</th>
                    <th className="px-4 py-3">{strings.usersAdmin.col.lastSignIn}</th>
                    <th className="px-4 py-3 text-right">
                      {strings.usersAdmin.col.searches} / {strings.usersAdmin.col.exports}
                    </th>
                    <th className="px-4 py-3">{strings.usersAdmin.col.fcm}</th>
                    <th className="px-4 py-3 text-right">{strings.usersAdmin.col.actions}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-hairline">
                  {pageItems.map((u) => {
                    const isSelf = currentUser?.uid === u.uid;
                    const protectedRow = isSelf || u.isAdmin;
                    const meta = [
                      u.providers.length ? providerLabel(u.providers) : null,
                      u.creationTime ? strings.usersAdmin.joinedOn(formatDate(u.creationTime)) : null,
                    ].filter(Boolean);
                    return (
                      <tr key={u.uid} className="transition hover:bg-subtle">
                        <td className="px-4 py-3">
                          <input
                            type="checkbox"
                            disabled={isSelf}
                            checked={selected.has(u.uid)}
                            onChange={() => toggleSelect(u.uid)}
                            className="h-4 w-4 accent-brand disabled:opacity-30"
                            aria-label={`Select ${u.email ?? u.uid}`}
                          />
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <Avatar name={u.displayName ?? u.email} photoUrl={u.photoUrl} size={36} />
                            <div className="min-w-0">
                              <p className="truncate font-semibold text-ink">
                                {u.displayName ?? '—'}
                              </p>
                              <p className="flex items-center gap-1 truncate text-xs text-muted">
                                <span className="truncate">{u.email ?? '—'}</span>
                                {u.emailVerified ? (
                                  <Icon
                                    name="check"
                                    className="h-3.5 w-3.5 shrink-0 text-success"
                                    aria-label={strings.usersAdmin.verified}
                                  />
                                ) : null}
                              </p>
                              {meta.length ? (
                                <p className="truncate text-xs text-faint">{meta.join(' · ')}</p>
                              ) : null}
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex flex-wrap items-center gap-1.5">
                            {u.disabled ? (
                              <Badge tone="danger">{strings.usersAdmin.statusDisabled}</Badge>
                            ) : (
                              <Badge tone="success">{strings.usersAdmin.statusActive}</Badge>
                            )}
                            {u.isAdmin ? <Badge tone="brand">{strings.usersAdmin.badgeAdmin}</Badge> : null}
                            {!u.hasProfile ? (
                              <Badge tone="neutral">{strings.usersAdmin.badgeNoProfile}</Badge>
                            ) : null}
                          </div>
                        </td>
                        <td
                          className="whitespace-nowrap px-4 py-3 text-sm text-muted"
                          title={formatIso(u.lastSignInTime)}
                        >
                          {formatDate(u.lastSignInTime)}
                        </td>
                        <td className="tnums whitespace-nowrap px-4 py-3 text-right text-sm text-body">
                          {u.searchCount} / {u.exportCount}
                        </td>
                        <td className="px-4 py-3">
                          {u.hasFcmToken ? (
                            <span
                              title={
                                u.fcmTokenUpdatedAt
                                  ? strings.usersAdmin.fcmUpdated(
                                      new Date(u.fcmTokenUpdatedAt).toLocaleString('en-GB'),
                                    )
                                  : undefined
                              }
                            >
                              <Badge tone="success">{strings.usersAdmin.fcmYes}</Badge>
                            </span>
                          ) : (
                            <Badge tone="neutral">{strings.usersAdmin.fcmNo}</Badge>
                          )}
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex justify-end">
                            <RowActions
                              actions={[
                                {
                                  label: strings.usersAdmin.edit,
                                  icon: 'pencil',
                                  onClick: () => openEdit(u),
                                },
                                {
                                  label: strings.usersAdmin.resetPassword,
                                  icon: 'key',
                                  onClick: () => void handleReset(u),
                                  disabled: !u.email,
                                },
                                {
                                  label: u.disabled ? strings.usersAdmin.unlock : strings.usersAdmin.lock,
                                  icon: u.disabled ? 'unlock' : 'lock',
                                  onClick: () =>
                                    setDialog({ kind: u.disabled ? 'unlock' : 'lock', user: u }),
                                  disabled: isSelf,
                                },
                                {
                                  label: strings.usersAdmin.delete,
                                  icon: 'trash',
                                  danger: true,
                                  onClick: () => setDialog({ kind: 'delete', user: u }),
                                  disabled: protectedRow,
                                },
                              ]}
                            />
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
              <Pagination
                page={pageSafe}
                totalPages={totalPages}
                total={filtered.length}
                pageSize={PAGE_SIZE}
                onPageChange={setPage}
              />
            </div>
          )}
        </Card>
      </div>

      {/* Create user */}
      {dialog?.kind === 'create' ? (
        <Modal
          title={strings.usersAdmin.createTitle}
          onClose={closeDialog}
          footer={
            <FormFooter
              busy={busy}
              onCancel={closeDialog}
              onConfirm={() => void handleCreate()}
              confirmLabel={strings.usersAdmin.create}
              disabled={!fEmail.trim() || fPassword.length < 6}
            />
          }
        >
          <div className="space-y-4">
            <Field label={strings.usersAdmin.fieldEmail}>
              <input
                type="email"
                value={fEmail}
                onChange={(e) => setFEmail(e.target.value)}
                className={inputClass}
              />
            </Field>
            <Field label={strings.usersAdmin.fieldPassword}>
              <input
                type="text"
                value={fPassword}
                onChange={(e) => setFPassword(e.target.value)}
                className={inputClass}
              />
            </Field>
            <Field label={strings.usersAdmin.fieldDisplayName}>
              <input
                type="text"
                value={fName}
                onChange={(e) => setFName(e.target.value)}
                className={inputClass}
              />
            </Field>
          </div>
        </Modal>
      ) : null}

      {/* Edit user */}
      {dialog?.kind === 'edit' ? (
        <Modal
          title={strings.usersAdmin.editTitle}
          onClose={closeDialog}
          footer={
            <FormFooter
              busy={busy}
              onCancel={closeDialog}
              onConfirm={() => void handleEdit(dialog.user)}
              confirmLabel={strings.usersAdmin.save}
              disabled={false}
            />
          }
        >
          <div className="space-y-4">
            <Field label={strings.usersAdmin.fieldDisplayName}>
              <input
                type="text"
                value={fName}
                onChange={(e) => setFName(e.target.value)}
                className={inputClass}
              />
            </Field>
            <Field label={strings.usersAdmin.fieldPhoto}>
              <input
                type="text"
                value={fPhoto}
                onChange={(e) => setFPhoto(e.target.value)}
                className={inputClass}
              />
            </Field>
          </div>
        </Modal>
      ) : null}

      {/* Lock / Unlock */}
      {dialog && (dialog.kind === 'lock' || dialog.kind === 'unlock') ? (
        <Modal
          title={
            dialog.kind === 'lock'
              ? strings.usersAdmin.lockConfirmTitle
              : strings.usersAdmin.unlockConfirmTitle
          }
          onClose={closeDialog}
          footer={
            <FormFooter
              busy={busy}
              onCancel={closeDialog}
              onConfirm={() => void handleToggleDisabled(dialog.user, dialog.kind === 'lock')}
              confirmLabel={dialog.kind === 'lock' ? strings.usersAdmin.lock : strings.usersAdmin.unlock}
              disabled={false}
            />
          }
        >
          <p className="text-sm text-body">
            {dialog.kind === 'lock'
              ? strings.usersAdmin.lockConfirmBody(dialog.user.email ?? dialog.user.uid)
              : strings.usersAdmin.unlockConfirmBody(dialog.user.email ?? dialog.user.uid)}
          </p>
        </Modal>
      ) : null}

      {/* Bulk lock */}
      {dialog?.kind === 'bulk-lock' ? (
        <Modal
          title={strings.usersAdmin.bulkLockTitle}
          onClose={closeDialog}
          footer={
            <FormFooter
              busy={busy}
              onCancel={closeDialog}
              onConfirm={() => void handleBulkLock()}
              confirmLabel={strings.usersAdmin.lock}
              disabled={false}
            />
          }
        >
          <p className="text-sm text-body">
            {strings.usersAdmin.bulkLockBody(
              users.filter((u) => selected.has(u.uid) && u.uid !== currentUser?.uid).length,
            )}
          </p>
        </Modal>
      ) : null}

      {/* Delete */}
      {dialog?.kind === 'delete' ? (
        <Modal
          title={strings.usersAdmin.deleteTitle}
          onClose={closeDialog}
          footer={
            <FormFooter
              busy={busy}
              onCancel={closeDialog}
              onConfirm={() => void handleDelete(dialog.user)}
              confirmLabel={strings.usersAdmin.delete}
              danger
              disabled={confirmEmail.trim() !== (dialog.user.email ?? '')}
            />
          }
        >
          <div className="flex items-start gap-2 rounded-md bg-danger/10 px-3 py-2.5 text-sm text-body">
            <Icon name="alert" className="mt-0.5 h-4 w-4 shrink-0 text-danger" />
            {strings.usersAdmin.deleteWarning}
          </div>
          <p className="mt-4 text-sm text-muted">
            {strings.usersAdmin.deleteTypeHint(dialog.user.email ?? dialog.user.uid)}
          </p>
          <input
            type="text"
            value={confirmEmail}
            onChange={(e) => setConfirmEmail(e.target.value)}
            placeholder={strings.usersAdmin.deleteTypePlaceholder}
            className="mt-2 w-full rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none placeholder:text-faint focus:border-danger focus:bg-card"
          />
        </Modal>
      ) : null}
    </div>
  );
}

const inputClass =
  'w-full rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none focus:border-brand focus:bg-card';

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <label className="mb-1 block text-xs font-bold text-muted">{label}</label>
      {children}
    </div>
  );
}

function FormFooter({
  busy,
  onCancel,
  onConfirm,
  confirmLabel,
  disabled,
  danger,
}: {
  busy: boolean;
  onCancel: () => void;
  onConfirm: () => void;
  confirmLabel: string;
  disabled: boolean;
  danger?: boolean;
}) {
  return (
    <>
      <button
        type="button"
        onClick={onCancel}
        disabled={busy}
        className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
      >
        {strings.common.cancel}
      </button>
      <button
        type="button"
        onClick={onConfirm}
        disabled={busy || disabled}
        className={`flex items-center gap-2 rounded-md px-4 py-2 text-sm font-bold text-white transition disabled:opacity-50 ${
          danger ? 'bg-danger hover:bg-danger/90' : 'bg-brand hover:bg-brand-bright'
        }`}
      >
        {busy ? <Spinner size={16} className="border-white" /> : null}
        {confirmLabel}
      </button>
    </>
  );
}
