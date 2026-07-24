import { useCallback, useEffect, useMemo, useState } from 'react';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { SectionTitle } from '../components/ui/SectionTitle';
import { Icon } from '../components/ui/Icon';
import { Badge } from '../components/ui/Badge';
import { Modal } from '../components/ui/Modal';
import { Spinner } from '../components/ui/Spinner';
import { Avatar } from '../components/ui/Avatar';
import { TableSkeleton } from '../components/ui/Skeleton';
import { useToast } from '../components/ui/Toast';
import { strings } from '../constants/strings';
import { formatDateTime } from '../lib/format';
import type {
  AppUser,
  NotificationRecord,
  NotificationTarget,
  NotificationTargetType,
} from '../types/models';
import {
  functionErrorMessage,
  sendNotification,
} from '../services/functionsService';
import { fetchNotificationHistory } from '../services/notificationsService';
import { fetchUsersPage } from '../services/usersService';

export function NotificationsPage() {
  const { showToast } = useToast();

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [targetType, setTargetType] = useState<NotificationTargetType>('all');
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [token, setToken] = useState('');
  const [pickerSearch, setPickerSearch] = useState('');

  const [users, setUsers] = useState<AppUser[]>([]);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [sending, setSending] = useState(false);

  const [history, setHistory] = useState<NotificationRecord[] | null>(null);
  const [historyError, setHistoryError] = useState(false);

  const loadHistory = useCallback(async () => {
    setHistoryError(false);
    try {
      setHistory(await fetchNotificationHistory());
    } catch {
      setHistoryError(true);
      setHistory([]);
    }
  }, []);

  useEffect(() => {
    void loadHistory();
    // Load a page of users for the picker (best-effort).
    fetchUsersPage({ sortBy: 'lastLoginAt', pageSize: 200 })
      .then((page) => setUsers(page.users))
      .catch(() => setUsers([]));
  }, [loadHistory]);

  const filteredUsers = useMemo(() => {
    const q = pickerSearch.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) =>
        (u.displayName ?? '').toLowerCase().includes(q) ||
        (u.email ?? '').toLowerCase().includes(q),
    );
  }, [users, pickerSearch]);

  const toggleUser = (uid: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(uid)) next.delete(uid);
      else next.add(uid);
      return next;
    });
  };

  const buildTarget = (): NotificationTarget => {
    if (targetType === 'uids') return { type: 'uids', uids: [...selected] };
    if (targetType === 'token') return { type: 'token', token: token.trim() };
    return { type: 'all' };
  };

  const validate = (): boolean => {
    if (!title.trim() || !body.trim()) {
      showToast(strings.notify.validation, 'error');
      return false;
    }
    if (targetType === 'uids' && selected.size === 0) {
      showToast(strings.notify.noTarget, 'error');
      return false;
    }
    if (targetType === 'token' && !token.trim()) {
      showToast(strings.notify.noTarget, 'error');
      return false;
    }
    return true;
  };

  const handleSend = async () => {
    setSending(true);
    try {
      const result = await sendNotification({
        title: title.trim(),
        body: body.trim(),
        target: buildTarget(),
      });
      showToast(strings.notify.sentToast(result.successCount));
      setConfirmOpen(false);
      await loadHistory();
    } catch (error) {
      showToast(functionErrorMessage(error, strings.notify.errorToast), 'error');
    } finally {
      setSending(false);
    }
  };

  const handleResend = (record: NotificationRecord) => {
    setTitle(record.title);
    setBody(record.body);
    setTargetType(record.targetType);
    if (record.targetType !== 'uids' && record.targetType !== 'token') {
      setSelected(new Set());
    }
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const confirmMessage =
    targetType === 'all'
      ? strings.notify.confirmAll
      : targetType === 'uids'
        ? strings.notify.confirmUids(selected.size)
        : strings.notify.confirmToken;

  return (
    <div>
      <PageHeader
        title={strings.pages.notifications.title}
        subtitle={strings.pages.notifications.subtitle}
      />

      <div className="mx-auto max-w-6xl space-y-6 px-4 py-6 sm:px-8 sm:py-8">
        <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
          {/* Form */}
          <Card>
            <SectionTitle icon="bell" title={strings.notify.formTitle} />
            <div className="mt-5 space-y-4">
              <div>
                <label className="mb-1 block text-xs font-bold text-muted">
                  {strings.notify.titleLabel}
                </label>
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder={strings.notify.titlePlaceholder}
                  className="w-full rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-bold text-muted">
                  {strings.notify.bodyLabel}
                </label>
                <textarea
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  rows={4}
                  placeholder={strings.notify.bodyPlaceholder}
                  className="w-full resize-y rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
                />
              </div>

              {/* Audience */}
              <div>
                <label className="mb-1 block text-xs font-bold text-muted">
                  {strings.notify.targetLabel}
                </label>
                <div className="flex flex-wrap gap-2">
                  {(
                    [
                      ['all', strings.notify.targetAll],
                      ['uids', strings.notify.targetPick],
                      ['token', strings.notify.targetToken],
                    ] as const
                  ).map(([value, label]) => (
                    <button
                      key={value}
                      type="button"
                      onClick={() => setTargetType(value)}
                      className={`rounded-md border px-3 py-2 text-sm font-semibold transition ${
                        targetType === value
                          ? 'border-brand bg-brand-soft text-brand'
                          : 'border-hairline text-muted hover:border-brand/40'
                      }`}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </div>

              {targetType === 'token' ? (
                <input
                  type="text"
                  value={token}
                  onChange={(e) => setToken(e.target.value)}
                  placeholder={strings.notify.tokenPlaceholder}
                  className="w-full rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
                />
              ) : null}

              {targetType === 'uids' ? (
                <div className="rounded-md border border-hairline">
                  <div className="border-b border-hairline p-2">
                    <input
                      type="text"
                      value={pickerSearch}
                      onChange={(e) => setPickerSearch(e.target.value)}
                      placeholder={strings.notify.pickerSearch}
                      className="w-full rounded-md bg-canvas px-3 py-2 text-sm text-ink outline-none placeholder:text-faint focus:bg-card"
                    />
                  </div>
                  <div className="max-h-56 overflow-y-auto p-1">
                    {filteredUsers.length === 0 ? (
                      <p className="p-4 text-center text-sm text-muted">
                        {strings.notify.pickerEmpty}
                      </p>
                    ) : (
                      filteredUsers.map((u) => (
                        <label
                          key={u.uid}
                          className="flex cursor-pointer items-center gap-3 rounded-md px-2 py-2 hover:bg-canvas"
                        >
                          <input
                            type="checkbox"
                            checked={selected.has(u.uid)}
                            onChange={() => toggleUser(u.uid)}
                            className="h-4 w-4 accent-brand"
                          />
                          <Avatar name={u.displayName ?? u.email} photoUrl={u.photoUrl} size={28} />
                          <div className="min-w-0 flex-1">
                            <p className="truncate text-sm font-semibold text-ink">
                              {u.displayName ?? '—'}
                            </p>
                            <p className="truncate text-xs text-muted">{u.email ?? '—'}</p>
                          </div>
                        </label>
                      ))
                    )}
                  </div>
                  <div className="border-t border-hairline px-3 py-2 text-xs font-semibold text-muted">
                    {strings.notify.selectedCount(selected.size)}
                  </div>
                </div>
              ) : null}

              <button
                type="button"
                onClick={() => {
                  if (validate()) setConfirmOpen(true);
                }}
                className="flex items-center justify-center gap-2 rounded-md bg-brand px-5 py-2.5 text-sm font-bold text-white transition hover:bg-brand-bright"
              >
                <Icon name="send" className="h-[18px] w-[18px]" />
                {strings.notify.sendButton}
              </button>
            </div>
          </Card>

          {/* Preview */}
          <div>
            <p className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">
              {strings.notify.previewTitle}
            </p>
            <div className="rounded-xl bg-ink p-3 shadow-soft">
              <div className="rounded-lg bg-white p-3">
                <div className="flex items-center gap-2">
                  <span className="grid h-6 w-6 place-items-center rounded bg-brand text-white">
                    <Icon name="spark" className="h-4 w-4" />
                  </span>
                  <span className="text-xs font-bold text-ink">
                    {strings.notify.previewApp}
                  </span>
                  <span className="ml-auto text-[11px] text-faint">
                    {strings.notify.previewNow}
                  </span>
                </div>
                <p className="mt-2 text-sm font-bold text-ink">
                  {title.trim() || strings.notify.titlePlaceholder}
                </p>
                <p className="mt-0.5 text-sm text-muted">
                  {body.trim() || strings.notify.bodyPlaceholder}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* History */}
        <Card className="!p-0">
          <div className="border-b border-hairline p-4">
            <SectionTitle icon="list" title={strings.notify.historyTitle} />
          </div>
          {history === null ? (
            <TableSkeleton rows={4} columns={4} />
          ) : historyError ? (
            <p className="p-6 text-center text-sm text-danger">{strings.notify.historyError}</p>
          ) : history.length === 0 ? (
            <p className="p-8 text-center text-sm text-muted">{strings.notify.historyEmpty}</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[720px] border-collapse text-left">
                <thead>
                  <tr className="border-b border-hairline text-xs font-bold uppercase tracking-wide text-muted">
                    <th className="px-4 py-3">{strings.notify.col.title}</th>
                    <th className="px-4 py-3">{strings.notify.col.audience}</th>
                    <th className="px-4 py-3">{strings.notify.col.result}</th>
                    <th className="px-4 py-3">{strings.notify.col.when}</th>
                    <th className="px-4 py-3" />
                  </tr>
                </thead>
                <tbody className="divide-y divide-hairline">
                  {history.map((n) => (
                    <tr key={n.id}>
                      <td className="max-w-[240px] px-4 py-3">
                        <p className="truncate text-sm font-semibold text-ink">{n.title}</p>
                        <p className="truncate text-xs text-muted">{n.body}</p>
                      </td>
                      <td className="px-4 py-3">
                        <Badge tone="neutral">{n.targetLabel}</Badge>
                      </td>
                      <td className="px-4 py-3 text-sm text-muted">
                        {strings.notify.resultOk(n.successCount, n.failureCount)}
                      </td>
                      <td className="whitespace-nowrap px-4 py-3 text-sm text-muted">
                        {formatDateTime(n.createdAt)}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <button
                          type="button"
                          onClick={() => handleResend(n)}
                          className="rounded-md border border-hairline px-3 py-1.5 text-xs font-semibold text-body transition hover:border-brand hover:text-brand"
                        >
                          {strings.notify.resend}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </div>

      {confirmOpen ? (
        <Modal
          title={strings.notify.confirmTitle}
          onClose={() => (sending ? undefined : setConfirmOpen(false))}
          footer={
            <>
              <button
                type="button"
                onClick={() => setConfirmOpen(false)}
                disabled={sending}
                className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
              >
                {strings.common.cancel}
              </button>
              <button
                type="button"
                onClick={() => void handleSend()}
                disabled={sending}
                className="flex items-center gap-2 rounded-md bg-brand px-4 py-2 text-sm font-bold text-white transition hover:bg-brand-bright disabled:opacity-60"
              >
                {sending ? <Spinner size={16} className="border-white" /> : null}
                {sending ? strings.notify.sending : strings.notify.confirmSend}
              </button>
            </>
          }
        >
          <p className="text-sm text-body">{confirmMessage}</p>
        </Modal>
      ) : null}
    </div>
  );
}
