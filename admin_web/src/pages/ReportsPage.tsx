import { useCallback, useEffect, useMemo, useState } from 'react';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { Badge } from '../components/ui/Badge';
import { Icon } from '../components/ui/Icon';
import { Modal } from '../components/ui/Modal';
import { Spinner } from '../components/ui/Spinner';
import { TableSkeleton } from '../components/ui/Skeleton';
import { EmptyState, ErrorState } from '../components/ui/StateView';
import { StatCard } from '../components/ui/StatCard';
import { useToast } from '../components/ui/Toast';
import { strings } from '../constants/strings';
import { formatBytes, formatDateTime } from '../lib/format';
import type { ReportDoc } from '../types/models';
import {
  deleteReport,
  fetchReports,
  type ReportsResult,
} from '../services/reportsService';

type RangeKey = '7' | '30' | 'all';
const DAY_MS = 24 * 60 * 60 * 1000;

export function ReportsPage() {
  const { showToast } = useToast();

  const [result, setResult] = useState<ReportsResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [topic, setTopic] = useState('all');
  const [range, setRange] = useState<RangeKey>('all');
  const [confirmTarget, setConfirmTarget] = useState<ReportDoc | null>(null);
  const [deleting, setDeleting] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      setResult(await fetchReports());
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const reports = result?.reports ?? [];

  const topics = useMemo(() => {
    const set = new Set(reports.map((r) => r.topic).filter(Boolean));
    return Array.from(set).sort((a, b) => a.localeCompare(b));
  }, [reports]);

  const filtered = useMemo(() => {
    const cutoff =
      range === 'all' ? 0 : Date.now() - Number(range) * DAY_MS;
    return reports.filter((r) => {
      if (topic !== 'all' && r.topic !== topic) return false;
      if (cutoff && (r.createdAt?.getTime() ?? 0) < cutoff) return false;
      return true;
    });
  }, [reports, topic, range]);

  const handleCopy = async (url: string) => {
    try {
      await navigator.clipboard.writeText(url);
      showToast(strings.common.copied);
    } catch {
      showToast(strings.reports.deleteError, 'error');
    }
  };

  const handleDelete = async () => {
    if (!confirmTarget) return;
    setDeleting(true);
    try {
      await deleteReport(confirmTarget);
      setResult((prev) =>
        prev
          ? {
              ...prev,
              reports: prev.reports.filter((r) => r.id !== confirmTarget.id),
              totalStorageBytes:
                prev.totalStorageBytes - (confirmTarget.sizeBytes ?? 0),
            }
          : prev,
      );
      showToast(strings.reports.deleteSuccess);
      setConfirmTarget(null);
    } catch {
      showToast(strings.reports.deleteError, 'error');
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div>
      <PageHeader
        title={strings.pages.reports.title}
        subtitle={strings.pages.reports.subtitle}
      />

      <div className="mx-auto max-w-6xl space-y-6 px-4 py-6 sm:px-8 sm:py-8">
        {/* Summary */}
        <div className="grid gap-4 sm:grid-cols-2">
          <StatCard
            icon="file"
            label={strings.overview.kpiReports}
            value={result ? reports.length : '—'}
          />
          <StatCard
            icon="inbox"
            label={strings.reports.totalSize}
            value={
              result && !result.storageUnavailable
                ? formatBytes(result.totalStorageBytes)
                : '—'
            }
          />
        </div>

        {result?.storageUnavailable ? (
          <div className="flex items-center gap-2 rounded-md bg-amber/10 px-4 py-3 text-sm text-body">
            <Icon name="alert" className="h-4 w-4 text-amber" />
            {strings.reports.storageWarning}
          </div>
        ) : null}

        <Card className="!p-0">
          {/* Filters */}
          <div className="flex flex-col gap-3 border-b border-hairline p-4 sm:flex-row sm:items-center">
            <div className="flex items-center gap-2">
              <label className="text-xs font-semibold text-muted">
                {strings.reports.filterTopic}
              </label>
              <select
                value={topic}
                onChange={(e) => setTopic(e.target.value)}
                className="max-w-[220px] rounded-md border border-hairline bg-card py-2 pl-3 pr-8 text-sm font-semibold text-ink outline-none focus:border-brand"
              >
                <option value="all">{strings.reports.allTopics}</option>
                {topics.map((t) => (
                  <option key={t} value={t}>
                    {t}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex items-center gap-2">
              <label className="text-xs font-semibold text-muted">
                {strings.reports.filterRange}
              </label>
              <select
                value={range}
                onChange={(e) => setRange(e.target.value as RangeKey)}
                className="rounded-md border border-hairline bg-card py-2 pl-3 pr-8 text-sm font-semibold text-ink outline-none focus:border-brand"
              >
                <option value="7">{strings.reports.range7}</option>
                <option value="30">{strings.reports.range30}</option>
                <option value="all">{strings.reports.rangeAll}</option>
              </select>
            </div>

            <span className="text-xs text-muted sm:ml-auto">
              {strings.reports.reportCount(filtered.length)}
            </span>
          </div>

          {/* Body */}
          {loading ? (
            <TableSkeleton rows={6} columns={5} />
          ) : error ? (
            <ErrorState
              message={strings.reports.errorMessage}
              onRetry={() => void load()}
            />
          ) : reports.length === 0 ? (
            <EmptyState
              icon="file"
              title={strings.reports.emptyTitle}
              message={strings.reports.emptyMessage}
            />
          ) : filtered.length === 0 ? (
            <EmptyState icon="file" title={strings.reports.noMatch} />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[760px] border-collapse text-left">
                <thead>
                  <tr className="border-b border-hairline text-xs font-bold uppercase tracking-wide text-muted">
                    <th className="px-4 py-3">{strings.reports.col.fileName}</th>
                    <th className="px-4 py-3">{strings.reports.col.topic}</th>
                    <th className="px-4 py-3">{strings.reports.col.exportedBy}</th>
                    <th className="px-4 py-3">{strings.reports.col.date}</th>
                    <th className="px-4 py-3 text-right">{strings.reports.col.size}</th>
                    <th className="px-4 py-3 text-right">{strings.reports.col.actions}</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-hairline">
                  {filtered.map((r) => (
                    <tr key={r.id} className="align-middle">
                      <td className="max-w-[220px] px-4 py-3">
                        <div className="flex items-center gap-2.5">
                          <span className="grid h-8 w-8 shrink-0 place-items-center rounded-md bg-brand-soft text-brand">
                            <Icon name="file" className="h-4 w-4" />
                          </span>
                          <span className="truncate text-sm font-semibold text-ink">
                            {r.fileName || '—'}
                          </span>
                        </div>
                      </td>
                      <td className="px-4 py-3">
                        <Badge>{r.topic}</Badge>
                      </td>
                      <td className="px-4 py-3 text-sm text-body">
                        {r.email ?? '—'}
                      </td>
                      <td className="px-4 py-3 text-sm text-muted">
                        {formatDateTime(r.createdAt)}
                      </td>
                      <td className="px-4 py-3 text-right text-sm text-muted">
                        {formatBytes(r.sizeBytes)}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center justify-end gap-1">
                          <a
                            href={r.downloadUrl}
                            target="_blank"
                            rel="noreferrer"
                            title={strings.common.open}
                            className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-canvas hover:text-brand"
                          >
                            <Icon name="external" className="h-[18px] w-[18px]" />
                          </a>
                          <button
                            type="button"
                            onClick={() => void handleCopy(r.downloadUrl)}
                            title={strings.common.copy}
                            className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-canvas hover:text-brand"
                          >
                            <Icon name="copy" className="h-[18px] w-[18px]" />
                          </button>
                          <button
                            type="button"
                            onClick={() => setConfirmTarget(r)}
                            title={strings.common.delete}
                            className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-danger/10 hover:text-danger"
                          >
                            <Icon name="trash" className="h-[18px] w-[18px]" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </div>

      {confirmTarget ? (
        <Modal
          title={strings.reports.deleteTitle}
          onClose={() => (deleting ? undefined : setConfirmTarget(null))}
          footer={
            <>
              <button
                type="button"
                onClick={() => setConfirmTarget(null)}
                disabled={deleting}
                className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:bg-canvas disabled:opacity-60"
              >
                {strings.common.cancel}
              </button>
              <button
                type="button"
                onClick={() => void handleDelete()}
                disabled={deleting}
                className="flex items-center gap-2 rounded-md bg-danger px-4 py-2 text-sm font-bold text-white transition hover:bg-danger/90 disabled:opacity-60"
              >
                {deleting ? <Spinner size={16} className="border-white" /> : null}
                {deleting ? strings.reports.deleting : strings.common.delete}
              </button>
            </>
          }
        >
          <p className="text-sm text-body">
            {strings.reports.deleteMessage(confirmTarget.fileName || confirmTarget.topic)}
          </p>
        </Modal>
      ) : null}
    </div>
  );
}
