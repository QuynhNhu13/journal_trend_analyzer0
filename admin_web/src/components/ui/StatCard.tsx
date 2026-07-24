import { Icon, type IconName } from './Icon';

/** KPI tile: brand-tinted icon square, big value, and a caption label. */
export function StatCard({
  icon,
  label,
  value,
}: {
  icon: IconName;
  label: string;
  value: string | number;
}) {
  return (
    <div className="rounded-lg border border-hairline bg-card p-5 shadow-soft">
      <div className="flex items-center gap-3">
        <span className="grid h-11 w-11 place-items-center rounded-md bg-brand-soft text-brand">
          <Icon name={icon} className="h-[22px] w-[22px]" />
        </span>
        <div className="min-w-0">
          <p className="truncate text-xs font-semibold uppercase tracking-wide text-muted">
            {label}
          </p>
          <p className="text-2xl font-extrabold leading-tight text-ink">{value}</p>
        </div>
      </div>
    </div>
  );
}
