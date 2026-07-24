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
import { RowActions } from '../components/ui/RowActions';
import { Pagination } from '../components/ui/Pagination';
import { useToast } from '../components/ui/Toast';
import { strings } from '../constants/strings';
import { formatDateTime } from '../lib/format';
import type {
  AppUser,
  NotificationRecord,
  NotificationTarget,
  TestFcmResult,
} from '../types/models';
import {
  functionErrorMessage,
  sendNotification,
  testFcmSend,
} from '../services/functionsService';
import {
  deleteNotificationRecord,
  fetchNotificationHistory,
} from '../services/notificationsService';
import { fetchUsersPage } from '../services/usersService';

type Audience = 'all' | 'uids' | 'token';

function parseData(text: string): Record<string, string> {
  const out: Record<string, string> = {};
  for (const line of text.split('\n')) {
    const idx = line.indexOf('=');
    if (idx <= 0) continue;
    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1).trim();
    // Only keep entries with a non-empty key AND value — never send blank data.
    if (key && value) out[key] = value;
  }
  return out;
}

export function NotificationsPage() {
  const { showToast } = useToast();

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [dataText, setDataText] = useState('');
  const [audience, setAudience] = useState<Audience>('all');
  const [token, setToken] = useState('');
  const [testResult, setTestResult] = useState<TestFcmResult | null>(null);
  const [testing, setTesting] = useState(false);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [pickerSearch, setPickerSearch] = useState('');

  const [users, setUsers] = useState<AppUser[]>([]);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [sending, setSending] = useState(false);

  const [history, setHistory] = useState<NotificationRecord[] | null>(null);
  const [historyError, setHistoryError] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<NotificationRecord | null>(null);
  const [failuresTarget, setFailuresTarget] = useState<NotificationRecord | null>(null);

  const [historyPage, setHistoryPage] = useState(1);
  const HISTORY_PAGE_SIZE = 10;

  // Sort history by newest first (sếp theo từ mới nhất)
  const sortedHistory = useMemo(() => {
    if (!history) return null;
    return [...history].sort((a, b) => {
      const getMs = (val: typeof a.createdAt) => {
        if (!val) return 0;
        if (typeof val === 'object' && 'seconds' in val && typeof val.seconds === 'number') {
          return val.seconds * 1000;
        }
        return new Date(val as string | Date).getTime();
      };
      return getMs(b.createdAt) - getMs(a.createdAt);
    });
  }, [history]);

  const totalHistoryPages = sortedHistory
    ? Math.max(1, Math.ceil(sortedHistory.length / HISTORY_PAGE_SIZE))
    : 1;
  const historyPageSafe = Math.min(historyPage, totalHistoryPages);

  const paginatedHistory = useMemo(() => {
    if (!sortedHistory) return [];
    return sortedHistory.slice(
      (historyPageSafe - 1) * HISTORY_PAGE_SIZE,
      historyPageSafe * HISTORY_PAGE_SIZE,
    );
  }, [sortedHistory, historyPageSafe]);

  useEffect(() => {
    setHistoryPage(1);
  }, [history]);

  const handleTestToken = async () => {

    if (!token.trim()) return;
    setTesting(true);
    setTestResult(null);
    try {
      const result = await testFcmSend({ token: token.trim() });
      setTestResult(result);
      if (!result.ok) console.error('[Notifications] testFcmSend error:', result);
    } catch (err) {
      console.error('[Notifications] testFcmSend threw:', err);
      setTestResult({
        ok: false,
        messageId: null,
        name: null,
        code: 'call-failed',
        message: functionErrorMessage(err, strings.notify.errorToast),
      });
    } finally {
      setTesting(false);
    }
  };

  const loadHistory = useCallback(async () => {
    setHistoryError(null);
    try {
      setHistory(await fetchNotificationHistory());
    } catch (err) {
      console.error('[Notifications] history load failed:', err);
      setHistoryError(functionErrorMessage(err, strings.notify.historyError));
      setHistory([]);
    }
  }, []);

  useEffect(() => {
    void loadHistory();
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
    if (audience === 'all') return { type: 'topic', topic: 'all' };
    if (audience === 'uids') return { type: 'uids', uids: [...selected] };
    return { type: 'token', token: token.trim() };
  };

  const validate = (): boolean => {
    if (!title.trim() || !body.trim()) {
      showToast(strings.notify.validation, 'error');
      return false;
    }
    if (audience === 'uids' && selected.size === 0) {
      showToast(strings.notify.noTarget, 'error');
      return false;
    }
    if (audience === 'token' && !token.trim()) {
      showToast(strings.notify.noTarget, 'error');
      return false;
    }
    return true;
  };

  const handleSend = async () => {
    setSending(true);
    try {
      const data = parseData(dataText);
      const result = await sendNotification({
        title: title.trim(),
        body: body.trim(),
        imageUrl: imageUrl.trim() || undefined,
        data: Object.keys(data).length ? data : undefined,
        target: buildTarget(),
      });
      // recipients === -1 means a topic broadcast (unknown count); only warn
      // when we explicitly resolved 0 device tokens.
      if (result.recipients === 0) {
        showToast(strings.notify.noTokens, 'error');
      } else if (result.failureCount > 0) {
        const first = result.failures[0];
        showToast(
          strings.notify.sendFailed(result.failureCount, first?.code ?? 'unknown'),
          'error',
        );
      } else {
        showToast(strings.notify.sentToast(result.successCount));
      }
      setConfirmOpen(false);
      await loadHistory();
    } catch (error) {
      console.error('[Notifications] sendNotification failed:', error);
      showToast(functionErrorMessage(error, strings.notify.errorToast), 'error');
    } finally {
      setSending(false);
    }
  };

  const handleDeleteRecord = async () => {
    if (!deleteTarget) return;
    try {
      await deleteNotificationRecord(deleteTarget.id);
      showToast(strings.notify.recordDeleted);
      setDeleteTarget(null);
      await loadHistory();
    } catch {
      showToast(strings.notify.recordDeleteError, 'error');
    }
  };

  const handleResend = (record: NotificationRecord) => {
    setTitle(record.title);
    setBody(record.body);
    setImageUrl(record.imageUrl ?? '');
    if (record.targetType === 'token') {
      setAudience('token');
    } else if (record.targetType === 'uids') {
      setAudience('uids');
    } else {
      setAudience('all');
    }
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const confirmMessage =
    audience === 'all'
      ? strings.notify.confirmAll
      : audience === 'uids'
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
                  rows={3}
                  placeholder={strings.notify.bodyPlaceholder}
                  className="w-full resize-y rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
                />
              </div>
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <label className="mb-1 block text-xs font-bold text-muted">
                    {strings.notify.imageLabel}
                  </label>
                  <input
                    type="text"
                    value={imageUrl}
                    onChange={(e) => setImageUrl(e.target.value)}
                    placeholder={strings.notify.imagePlaceholder}
                    className="w-full rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-xs font-bold text-muted">
                    {strings.notify.dataLabel}
                  </label>
                  <textarea
                    value={dataText}
                    onChange={(e) => setDataText(e.target.value)}
                    rows={2}
                    placeholder={strings.notify.dataPlaceholder}
                    className="w-full resize-y rounded-md border border-hairline bg-canvas px-3 py-2.5 font-mono text-xs text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
                  />
                </div>
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
                      onClick={() => setAudience(value)}
                      className={`rounded-md border px-3 py-2 text-sm font-semibold transition ${
                        audience === value
                          ? 'border-brand bg-brand-soft text-brand'
                          : 'border-hairline text-muted hover:border-brand/40'
                      }`}
                    >
                      {label}
                    </button>
                  ))}
                </div>
              </div>

              {audience === 'token' ? (
                <div className="space-y-2">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={token}
                      onChange={(e) => {
                        setToken(e.target.value);
                        setTestResult(null);
                      }}
                      placeholder={strings.notify.tokenPlaceholder}
                      className="w-full rounded-md border border-hairline bg-canvas px-3 py-2.5 text-sm text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
                    />
                    <button
                      type="button"
                      onClick={() => void handleTestToken()}
                      disabled={testing || !token.trim()}
                      className="shrink-0 rounded-md border border-hairline px-3 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand disabled:opacity-60"
                    >
                      {testing ? strings.notify.testing : strings.notify.test}
                    </button>
                  </div>
                  {testResult ? (
                    <div
                      className={`flex items-start gap-2 rounded-md border px-3 py-2 text-sm ${
                        testResult.ok
                          ? 'border-success/30 bg-success/5 text-body'
                          : 'border-danger/30 bg-danger/5 text-body'
                      }`}
                    >
                      <Icon
                        name={testResult.ok ? 'check' : 'alert'}
                        className={`mt-0.5 h-4 w-4 shrink-0 ${testResult.ok ? 'text-success' : 'text-danger'}`}
                      />
                      <span className="break-all">
                        {testResult.ok
                          ? strings.notify.testOk(testResult.messageId ?? '')
                          : `${testResult.code ?? testResult.name ?? 'error'}: ${testResult.message ?? ''}`}
                      </span>
                    </div>
                  ) : null}
                </div>
              ) : null}

              {audience === 'uids' ? (
                <UserPicker
                  users={filteredUsers}
                  search={pickerSearch}
                  onSearch={setPickerSearch}
                  selected={selected}
                  onToggle={toggleUser}
                />
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

          {/* Preview + subscription */}
          <div className="space-y-6">
            <div>
              <p className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">
                {strings.notify.previewTitle}
              </p>
              <div className="rounded-2xl border border-pink-200/80 bg-gradient-to-br from-pink-100/90 via-rose-50 to-pink-50 p-3.5 shadow-soft">
                <div className="overflow-hidden rounded-xl bg-white shadow-xs border border-pink-100/80">
                  <div className="p-3.5">
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
                  {imageUrl.trim() ? (
                    <img
                      src={imageUrl.trim()}
                      alt=""
                      className="max-h-40 w-full object-cover"
                      onError={(e) => {
                        (e.currentTarget as HTMLImageElement).style.display = 'none';
                      }}
                    />
                  ) : null}
                </div>
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
            <p className="p-6 text-center text-sm text-danger">
              {historyError ?? strings.notify.historyError}
            </p>
          ) : sortedHistory === null || sortedHistory.length === 0 ? (
            <p className="p-8 text-center text-sm text-muted">{strings.notify.historyEmpty}</p>
          ) : (
            <div>
              <div className="overflow-x-auto">
                <table className="w-full min-w-[760px] border-collapse text-left">
                  <thead>
                    <tr className="border-b border-hairline text-label uppercase text-muted [&>th]:sticky [&>th]:top-0 [&>th]:z-[5] [&>th]:bg-subtle">
                      <th className="px-4 py-3">{strings.notify.col.title}</th>
                      <th className="px-4 py-3">{strings.notify.col.audience}</th>
                      <th className="px-4 py-3">{strings.notify.col.result}</th>
                      <th className="px-4 py-3">{strings.notify.col.when}</th>
                      <th className="px-4 py-3" />
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-hairline">
                    {paginatedHistory.map((n) => (
                      <tr key={n.id} className="transition hover:bg-subtle">
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
                        <td className="px-4 py-3">
                          <div className="flex justify-end">
                            <RowActions
                              actions={[
                                {
                                  label: strings.notify.resend,
                                  icon: 'send',
                                  onClick: () => handleResend(n),
                                },
                                ...(n.failures.length > 0
                                  ? [
                                      {
                                        label: strings.notify.viewErrors,
                                        icon: 'alert' as const,
                                        onClick: () => setFailuresTarget(n),
                                      },
                                    ]
                                  : []),
                                {
                                  label: strings.notify.deleteRecord,
                                  icon: 'trash' as const,
                                  danger: true,
                                  onClick: () => setDeleteTarget(n),
                                },
                              ]}
                            />
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <Pagination
                page={historyPageSafe}
                totalPages={totalHistoryPages}
                total={sortedHistory.length}
                pageSize={HISTORY_PAGE_SIZE}
                onPageChange={setHistoryPage}
              />
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

      {deleteTarget ? (
        <Modal
          title={strings.notify.deleteRecord}
          onClose={() => setDeleteTarget(null)}
          footer={
            <>
              <button
                type="button"
                onClick={() => setDeleteTarget(null)}
                className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas"
              >
                {strings.common.cancel}
              </button>
              <button
                type="button"
                onClick={() => void handleDeleteRecord()}
                className="rounded-md bg-danger px-4 py-2 text-sm font-bold text-white transition hover:bg-danger/90"
              >
                {strings.common.delete}
              </button>
            </>
          }
        >
          <p className="text-sm text-body">“{deleteTarget.title}”</p>
        </Modal>
      ) : null}

      {failuresTarget ? (
        <Modal
          title={strings.notify.errorsTitle}
          size="lg"
          onClose={() => setFailuresTarget(null)}
          footer={
            <button
              type="button"
              onClick={() => setFailuresTarget(null)}
              className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas"
            >
              {strings.common.close}
            </button>
          }
        >
          <div className="overflow-x-auto">
            <table className="w-full min-w-[520px] border-collapse text-left">
              <thead>
                <tr className="border-b border-hairline text-label uppercase text-muted">
                  <th className="px-3 py-2">{strings.notify.errorCol.code}</th>
                  <th className="px-3 py-2">{strings.notify.errorCol.token}</th>
                  <th className="px-3 py-2">{strings.notify.errorCol.message}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-hairline">
                {failuresTarget.failures.map((f, i) => (
                  <tr key={`${f.tokenSuffix}-${i}`}>
                    <td className="px-3 py-2">
                      <Badge tone="danger">{f.code}</Badge>
                    </td>
                    <td className="px-3 py-2 font-mono text-xs text-muted">{f.tokenSuffix}</td>
                    <td className="px-3 py-2 text-sm text-body">{f.message || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Modal>
      ) : null}
    </div>
  );
}

// ── Reusable searchable user picker ──
function UserPicker({
  users,
  search,
  onSearch,
  selected,
  onToggle,
}: {
  users: AppUser[];
  search: string;
  onSearch: (v: string) => void;
  selected: Set<string>;
  onToggle: (uid: string) => void;
}) {
  return (
    <div className="rounded-md border border-hairline">
      <div className="border-b border-hairline p-2">
        <input
          type="text"
          value={search}
          onChange={(e) => onSearch(e.target.value)}
          placeholder={strings.notify.pickerSearch}
          className="w-full rounded-md bg-canvas px-3 py-2 text-sm text-ink outline-none placeholder:text-faint focus:bg-card"
        />
      </div>
      <div className="max-h-56 overflow-y-auto p-1">
        {users.length === 0 ? (
          <p className="p-4 text-center text-sm text-muted">{strings.notify.pickerEmpty}</p>
        ) : (
          users.map((u) => (
            <label
              key={u.uid}
              className="flex cursor-pointer items-center gap-3 rounded-md px-2 py-2 hover:bg-canvas"
            >
              <input
                type="checkbox"
                checked={selected.has(u.uid)}
                onChange={() => onToggle(u.uid)}
                className="h-4 w-4 accent-brand"
              />
              <Avatar name={u.displayName ?? u.email} photoUrl={u.photoUrl} size={28} />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-ink">{u.displayName ?? '—'}</p>
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
  );
}
