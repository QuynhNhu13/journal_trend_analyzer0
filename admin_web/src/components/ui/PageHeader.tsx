import type { ReactNode } from 'react';

/**
 * Pink gradient hero header with rounded bottom corners — the web twin of the
 * Flutter app's BrandedHeader (large title + small subtitle on AppGradients.brand).
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
    <header className="rounded-b-xl bg-brand px-5 py-6 text-white shadow-brand sm:px-8 sm:py-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-extrabold tracking-tight sm:text-[26px]">
            {title}
          </h1>
          {subtitle ? (
            <p className="mt-1 text-sm text-white/90">{subtitle}</p>
          ) : null}
        </div>
        {actions ? <div className="flex items-center gap-2">{actions}</div> : null}
      </div>
    </header>
  );
}
