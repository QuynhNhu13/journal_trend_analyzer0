import type { DailyCount } from '../../types/models';

/**
 * Minimal self-drawn bar chart (no chart library). Bars are absolute-pixel
 * heights inside a fixed-height, bottom-aligned track so heights resolve
 * reliably and the whole row stays responsive.
 */
export function BarChart({ data }: { data: DailyCount[] }) {
  const CHART_HEIGHT = 176; // px
  const BAR_MAX = 150; // leave headroom for the value label
  const max = Math.max(1, ...data.map((d) => d.count));

  return (
    <div>
      <div className="flex items-end gap-1.5" style={{ height: CHART_HEIGHT }}>
        {data.map((d) => {
          const barPx = d.count > 0 ? Math.max(4, Math.round((d.count / max) * BAR_MAX)) : 0;
          return (
            <div
              key={d.day}
              className="flex flex-1 flex-col items-center justify-end gap-1"
              style={{ height: CHART_HEIGHT }}
            >
              {d.count > 0 ? (
                <span className="text-[10px] font-bold text-brand">{d.count}</span>
              ) : null}
              <div
                title={`${d.label}: ${d.count}`}
                style={{ height: barPx }}
                className="w-full max-w-[26px] rounded-t-md bg-brand/80 transition-colors hover:bg-brand"
              />
            </div>
          );
        })}
      </div>
      <div className="mt-2 flex gap-1.5">
        {data.map((d, i) => (
          <span key={d.day} className="flex-1 text-center text-[10px] text-faint">
            {i % 2 === 0 ? d.label : ''}
          </span>
        ))}
      </div>
    </div>
  );
}
