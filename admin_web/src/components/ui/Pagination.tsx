import { useEffect, useMemo, useState, type ReactNode } from 'react';

import { strings } from '../../constants/strings';

/**
 * Client-side pagination helper. Clamps the current page when the list shrinks
 * (delete / filter) so the view can never point past the last page.
 */
export function usePagination<T>(items: T[], pageSize: number) {
  const [page, setPage] = useState(1);
  const totalPages = Math.max(1, Math.ceil(items.length / pageSize));
  const pageSafe = Math.min(page, totalPages);

  // Keep internal state in sync when the clamp kicks in (e.g. rows removed).
  useEffect(() => {
    if (page !== pageSafe) setPage(pageSafe);
  }, [page, pageSafe]);

  const pageItems = useMemo(
    () => items.slice((pageSafe - 1) * pageSize, pageSafe * pageSize),
    [items, pageSafe, pageSize],
  );

  return { page: pageSafe, setPage, totalPages, pageItems, pageSize };
}

/**
 * Shared table footer: "Showing a–b of N" + Prev / Page x of y / Next.
 * Renders nothing when there is only a single page and no extra slot, so tables
 * never show an empty footer bar.
 */
export function Pagination({
  page,
  totalPages,
  total,
  pageSize,
  onPageChange,
  extra,
}: {
  page: number;
  totalPages: number;
  total: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  /** Optional slot (e.g. a "Load more" button) shown on the left. */
  extra?: ReactNode;
}) {
  if (total === 0 || (totalPages <= 1 && !extra)) return null;

  const from = (page - 1) * pageSize + 1;
  const to = Math.min(page * pageSize, total);

  return (
    <div className="flex flex-col items-center justify-between gap-3 border-t border-hairline p-4 sm:flex-row">
      <div className="flex items-center gap-3">
        <p className="text-xs text-muted">{strings.common.showing(from, to, total)}</p>
        {extra}
      </div>
      <div className="flex items-center gap-2">
        <button
          type="button"
          onClick={() => onPageChange(Math.max(1, page - 1))}
          disabled={page <= 1}
          className="rounded-md border border-hairline px-3 py-1.5 text-sm font-semibold text-body transition hover:border-brand hover:text-brand disabled:cursor-not-allowed disabled:opacity-40"
        >
          {strings.common.previous}
        </button>
        <span className="tnums px-1 text-sm text-body">
          {strings.common.pageOf(page, totalPages)}
        </span>
        <button
          type="button"
          onClick={() => onPageChange(Math.min(totalPages, page + 1))}
          disabled={page >= totalPages}
          className="rounded-md border border-hairline px-3 py-1.5 text-sm font-semibold text-body transition hover:border-brand hover:text-brand disabled:cursor-not-allowed disabled:opacity-40"
        >
          {strings.common.next}
        </button>
      </div>
    </div>
  );
}
