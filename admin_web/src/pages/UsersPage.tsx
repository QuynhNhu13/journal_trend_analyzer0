import { useCallback, useEffect, useMemo, useState } from 'react';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { Avatar } from '../components/ui/Avatar';
import { Badge } from '../components/ui/Badge';
import { Icon } from '../components/ui/Icon';
import { Modal } from '../components/ui/Modal';
import { Spinner } from '../components/ui/Spinner';
import { TableSkeleton } from '../components/ui/Skeleton';
import { EmptyState, ErrorState } from '../components/ui/StateView';
import { useToast } from '../components/ui/Toast';
import { useAuth } from '../context/AuthContext';
import { strings } from '../constants/strings';
import type { AuthUserView } from '../types/models';
import {
  deleteUser,
  functionErrorMessage,
  listAuthUsers,
  setUserDisabled,
} from '../services/functionsService';

function formatIso(value: string | null): string {
  if (!value) return '—';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '—' : date.toLocaleString('en-GB');
}

type Dialog =
  | { kind: 'lock' | 'unlock'; user: AuthUserView }
  | { kind: 'delete'; user: AuthUserView }
  | null;

export function UsersPage() {
  const { showToast } = useToast();
  const { user: currentUser } = useAuth();

  const [users, setUsers] = useState<AuthUserView[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [search, setSearch] = useState('');
  const [dialog, setDialog] = useState<Dialog>(null);
  const [busy, setBusy] = useState(false);
  const [confirmEmail, setConfirmEmail] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      const result = await listAuthUsers({});
      setUsers(result.users);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) =>
        (u.displayName ?? '').toLowerCase().includes(q) ||
        (u.email ?? '').toLowerCase().includes(q),
    );
  }, [users, search]);

  const closeDialog = () => {
    if (busy) return;
    setDialog(null);
    setConfirmEmail('');
  };

  const handleToggleDisabled = async (target: AuthUserView, disabled: boolean) => {
    setBusy(true);
    try {
      await setUserDisabled({ uid: target.uid, disabled });
      setUsers((prev) =>
        prev.map((u) => (u.uid === target.uid ? { ...u, disabled } : u)),
      );
      showToast(disabled ? strings.usersAdmin.lockedToast : strings.usersAdmin.unlockedToast);
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
      showToast(
        strings.usersAdmin.deleteSummary(result.reportsDeleted, result.filesDeleted),
      );
      setDialog(null);
      setConfirmEmail('');
    } catch (err) {
      showToast(functionErrorMessage(err, strings.usersAdmin.deleteError), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader
        title={strings.pages.users.title}
        subtitle={strings.pages.users.subtitle}
      />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-8 sm:py-8">
        <Card className="!p-0">
          <div className="flex flex-col gap-3 border-b border-hairline p-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative sm:w-80">
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
            <div className="flex items-center gap-3">
              <span className="text-xs text-muted">{strings.usersAdmin.countLabel(users.length)}</span>
              <button
                type="button"
                onClick={() => void load()}
                className="flex items-center gap-2 rounded-md border border-hairline px-3 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand"
              >
                <Icon name="refresh" className="h-4 w-4" />
                {strings.usersAdmin.reload}
              </button>
            </div>
          </div>

          {loading ? (
            <TableSkeleton rows={6} columns={5} />
          ) : error ? (
            <ErrorState message={strings.usersAdmin.errorMessage} onRetry={() => void load()} />
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
              <table className="w-full min-w-[820px] border-collapse text-left">
                <thead>
                  <tr className="border-b border-hairline text-xs font-bold uppercase tracking-wide text-muted">
                    <th className="px-4 py-3">{strings.usersAdmin.col.user}</th>
                    <th className="px-4 py-3">{strings.usersAdmin.col.status}</th>
                    <th className="px-4 py-3">{strings.usersAdmin.col.created}</th>
                    <th className="px-4 py-3">{strings.usersAdmin.col.lastSignIn}</th>
                    <th className="px-4 py-3 text-right">{strings.usersAdmin.col.actions}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-hairline">
                  {filtered.map((u) => {
                    const isSelf = currentUser?.uid === u.uid;
                    const protectedRow = isSelf || u.isAdmin;
                    return (
                      <tr key={u.uid}>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <Avatar name={u.displayName ?? u.email} photoUrl={u.photoUrl} size={36} />
                            <div className="min-w-0">
                              <p className="truncate font-semibold text-ink">
                                {u.displayName ?? '—'}
                              </p>
                              <p className="truncate text-xs text-muted">{u.email ?? '—'}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex flex-wrap items-center gap-1.5">
                            {u.disabled ? (
                              <span className="inline-flex items-center gap-1 rounded-full bg-danger/10 px-2.5 py-0.5 text-xs font-bold text-danger">
                                {strings.usersAdmin.statusDisabled}
                              </span>
                            ) : (
                              <span className="inline-flex items-center gap-1 rounded-full bg-emerald/10 px-2.5 py-0.5 text-xs font-bold text-emerald">
                                {strings.usersAdmin.statusActive}
                              </span>
                            )}
                            {u.isAdmin ? <Badge>{strings.usersAdmin.badgeAdmin}</Badge> : null}
                            {!u.hasProfile ? (
                              <Badge tone="neutral">{strings.usersAdmin.badgeNoProfile}</Badge>
                            ) : null}
                          </div>
                        </td>
                        <td className="whitespace-nowrap px-4 py-3 text-sm text-muted">
                          {formatIso(u.creationTime)}
                        </td>
                        <td className="whitespace-nowrap px-4 py-3 text-sm text-muted">
                          {formatIso(u.lastSignInTime)}
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center justify-end gap-1">
                            <button
                              type="button"
                              disabled={isSelf}
                              onClick={() =>
                                setDialog({ kind: u.disabled ? 'unlock' : 'lock', user: u })
                              }
                              title={u.disabled ? strings.usersAdmin.unlock : strings.usersAdmin.lock}
                              className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-canvas hover:text-brand disabled:opacity-30"
                            >
                              <Icon name={u.disabled ? 'unlock' : 'lock'} className="h-[18px] w-[18px]" />
                            </button>
                            <button
                              type="button"
                              disabled={protectedRow}
                              onClick={() => setDialog({ kind: 'delete', user: u })}
                              title={
                                isSelf
                                  ? strings.usersAdmin.cannotSelf
                                  : u.isAdmin
                                    ? strings.usersAdmin.cannotAdmin
                                    : strings.usersAdmin.delete
                              }
                              className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-danger/10 hover:text-danger disabled:opacity-30"
                            >
                              <Icon name="trash" className="h-[18px] w-[18px]" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </div>

      {/* Lock / Unlock confirm */}
      {dialog && dialog.kind !== 'delete' ? (
        <Modal
          title={
            dialog.kind === 'lock'
              ? strings.usersAdmin.lockConfirmTitle
              : strings.usersAdmin.unlockConfirmTitle
          }
          onClose={closeDialog}
          footer={
            <>
              <button
                type="button"
                onClick={closeDialog}
                disabled={busy}
                className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
              >
                {strings.common.cancel}
              </button>
              <button
                type="button"
                onClick={() => void handleToggleDisabled(dialog.user, dialog.kind === 'lock')}
                disabled={busy}
                className="flex items-center gap-2 rounded-md bg-brand px-4 py-2 text-sm font-bold text-white transition hover:bg-brand-bright disabled:opacity-60"
              >
                {busy ? <Spinner size={16} className="border-white" /> : null}
                {dialog.kind === 'lock' ? strings.usersAdmin.lock : strings.usersAdmin.unlock}
              </button>
            </>
          }
        >
          <p className="text-sm text-body">
            {dialog.kind === 'lock'
              ? strings.usersAdmin.lockConfirmBody(dialog.user.email ?? dialog.user.uid)
              : strings.usersAdmin.unlockConfirmBody(dialog.user.email ?? dialog.user.uid)}
          </p>
        </Modal>
      ) : null}

      {/* Delete confirm (type-to-confirm) */}
      {dialog && dialog.kind === 'delete' ? (
        <Modal
          title={strings.usersAdmin.deleteTitle}
          onClose={closeDialog}
          footer={
            <>
              <button
                type="button"
                onClick={closeDialog}
                disabled={busy}
                className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
              >
                {strings.common.cancel}
              </button>
              <button
                type="button"
                onClick={() => void handleDelete(dialog.user)}
                disabled={busy || confirmEmail.trim() !== (dialog.user.email ?? '')}
                className="flex items-center gap-2 rounded-md bg-danger px-4 py-2 text-sm font-bold text-white transition hover:bg-danger/90 disabled:opacity-50"
              >
                {busy ? <Spinner size={16} className="border-white" /> : null}
                {strings.usersAdmin.delete}
              </button>
            </>
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
