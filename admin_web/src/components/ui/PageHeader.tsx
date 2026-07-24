import type { ReactNode } from 'react';

/**
 * Page header with clean typography and subtle pink backdrop polish.
 */
export function PageHeader({
  title,
  subtitle,
  actions,
}: {
  title: string;
  subtitle?: string;
  actions?: ReactNode;
}) {
  return (
    <header className="border-b border-pink-100/60 bg-gradient-to-r from-white via-pink-50/20 to-white shadow-xs">
      <div className="mx-auto flex max-w-6xl flex-col gap-3 px-4 py-5 sm:flex-row sm:items-center sm:justify-between sm:px-8 sm:py-6">
        <div className="min-w-0">
          <h1 className="text-2xl font-black text-ink tracking-tight">{title}</h1>
          {subtitle ? <p className="mt-1 text-xs sm:text-sm font-medium text-muted">{subtitle}</p> : null}
        </div>
        {actions ? <div className="flex items-center gap-2.5">{actions}</div> : null}
      </div>
    </header>
  );
}

