import type { ReactNode } from 'react';

import { Icon, type IconName } from './Icon';

/**
 * KPI tile: uppercase label, tabular metric, and pink icon accent container.
 */
export function StatCard({
  icon,
  label,
  value,
  sub,
}: {
  icon?: IconName;
  label: string;
  value: string | number;
  sub?: ReactNode;
}) {
  return (
    <div className="group rounded-2xl border border-pink-100/90 bg-white p-5 shadow-soft transition-all duration-200 hover:-translate-y-0.5 hover:border-pink-300 hover:shadow-brand/10">
      <div className="flex items-center justify-between">
        <p className="text-label uppercase tracking-wider text-muted font-bold">{label}</p>
        {icon ? (
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-gradient-to-br from-pink-50 to-rose-100/60 text-brand shadow-xs transition-transform group-hover:scale-110">
            <Icon name={icon} className="h-5 w-5" />
          </span>
        ) : null}
      </div>
      <p className="mt-2.5 text-3xl font-extrabold tnums text-ink tracking-tight">{value}</p>
      {sub ? <p className="mt-1.5 text-xs font-medium text-muted">{sub}</p> : null}
    </div>
  );
}

