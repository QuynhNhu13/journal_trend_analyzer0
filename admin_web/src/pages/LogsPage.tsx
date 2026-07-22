import { useCallback, useEffect, useMemo, useState } from 'react';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { TableSkeleton } from '../components/ui/Skeleton';
import { EmptyState, ErrorState } from '../components/ui/StateView';
import { strings } from '../constants/strings';
import { formatDateTime } from '../lib/format';
import type { AdminLog } from '../types/models';
import { fetchLogsPage, type LogCursor } from '../services/logsService';

const PAGE_SIZE = 25;

export function LogsPage() {
  const [logs, setLogs] = useState<AdminLog[]>([]);
  const [cursor, setCursor] = useState<LogCursor | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState(false);
  const [action, setAction] = useState('all');

  const loadFirst = useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      const page = await fetchLogsPage({ pageSize: PAGE_SIZE });
      setLogs(page.logs);
      setCursor(page.cursor);
      setHasMore(page.hasMore);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadFirst();
  }, [loadFirst]);

  const loadMore = async () => {
    if (!cursor || loadingMore) return;
    setLoadingMore(true);
    try {
      const page = await fetchLogsPage({ pageSize: PAGE_SIZE, cursor });
      setLogs((prev) => [...prev, ...page.logs]);
      setCursor(page.cursor);
      setHasMore(page.hasMore);
    } catch {
      setError(true);
    } finally {
      setLoadingMore(false);
    }
  };

  const actions = useMemo(() => {
    return Array.from(new Set(logs.map((l) => l.action))).sort();
  }, [logs]);

  const filtered = useMemo(
    () => (action === 'all' ? logs : logs.filter((l) => l.action === action)),
    [logs, action],
  );

  return (
    <div>
      <PageHeader title={strings.pages.logs.title} subtitle={strings.pages.logs.subtitle} />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-8 sm:py-8">
        <Card className="!p-0">
          <div className="flex flex-col gap-3 border-b border-hairline p-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-center gap-2">
              <label className="text-xs font-semibold text-muted">
                {strings.logs.filterAction}
              </label>
              <select
                value={action}
                onChange={(e) => setAction(e.target.value)}
                className="rounded-md border border-hairline bg-card py-2 pl-3 pr-8 text-sm font-semibold text-ink outline-none focus:border-brand"
              >
                <option value="all">{strings.logs.allActions}</option>
                {actions.map((a) => (
                  <option key={a} value={a}>
                    {a}
                  </option>
                ))}
              </select>
            </div>
            <span className="text-xs text-muted">{strings.logs.countLabel(logs.length)}</span>
          </div>

          {loading ? (
            <TableSkeleton rows={6} columns={5} />
          ) : error ? (
            <ErrorState message={strings.logs.errorMessage} onRetry={() => void loadFirst()} />
          ) : logs.length === 0 ? (
            <EmptyState icon="list" title={strings.logs.emptyTitle} message={strings.logs.emptyMessage} />
          ) : filtered.length === 0 ? (
            <EmptyState icon="list" title={strings.logs.noMatch} />
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full min-w-[720px] border-collapse text-left">
                  <thead>
                    <tr className="border-b border-hairline text-xs font-bold uppercase tracking-wide text-muted">
                      <th className="px-4 py-3">{strings.logs.col.when}</th>
                      <th className="px-4 py-3">{strings.logs.col.actor}</th>
                      <th className="px-4 py-3">{strings.logs.col.action}</th>
                      <th className="px-4 py-3">{strings.logs.col.target}</th>
                      <th className="px-4 py-3">{strings.logs.col.result}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-hairline">
                    {filtered.map((l) => (
                      <tr key={l.id}>
                        <td className="whitespace-nowrap px-4 py-3 text-sm text-muted">
                          {formatDateTime(l.createdAt)}
                        </td>
                        <td className="px-4 py-3 text-sm text-body">{l.actorEmail ?? '—'}</td>
                        <td className="px-4 py-3">
                          <Badge>{l.action}</Badge>
                        </td>
                        <td className="max-w-[200px] truncate px-4 py-3 text-sm text-muted" title={l.targetId ?? ''}>
                          {l.targetId ?? '—'}
                        </td>
                        <td className="px-4 py-3 text-sm text-muted">{l.result ?? '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="flex items-center justify-end border-t border-hairline p-4">
                {hasMore && action === 'all' ? (
                  <button
                    type="button"
                    onClick={() => void loadMore()}
                    disabled={loadingMore}
                    className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand disabled:opacity-60"
                  >
                    {loadingMore ? strings.states.loading : strings.common.loadMore}
                  </button>
                ) : null}
              </div>
            </>
          )}
        </Card>
      </div>
    </div>
  );
}
