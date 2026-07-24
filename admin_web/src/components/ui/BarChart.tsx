import type { DailyCount } from '../../types/models';

/**
 * Bar chart styled in signature pink gradient theme.
 */
export function BarChart({ data }: { data: DailyCount[] }) {
  const CHART_HEIGHT = 176; // px
  const BAR_MAX = 150; // leave headroom for the value label
  const max = Math.max(1, ...data.map((d) => d.count));

  return (
    <div>
      <div className="flex items-end gap-1.5" style={{ height: CHART_HEIGHT }}>
        {data.map((d) => {
          const barPx = d.count > 0 ? Math.max(6, Math.round((d.count / max) * BAR_MAX)) : 0;
          return (
            <div
              key={d.day}
              className="group flex flex-1 flex-col items-center justify-end gap-1"
              style={{ height: CHART_HEIGHT }}
            >
              {d.count > 0 ? (
                <span className="text-[10px] font-extrabold text-brand transition-transform group-hover:scale-110">{d.count}</span>
              ) : null}
              <div
                title={`${d.label}: ${d.count}`}
                style={{ height: barPx }}
                className="w-full max-w-[28px] rounded-t-lg bg-gradient-to-t from-brand via-brand-bright to-pink-400 transition-all duration-200 group-hover:shadow-brand/40 group-hover:shadow-md group-hover:brightness-110"
              />
            </div>
          );
        })}
      </div>
      <div className="mt-3 flex gap-1.5 border-t border-pink-100 pt-2">
        {data.map((d, i) => (
          <span key={d.day} className="flex-1 text-center text-[10px] font-bold text-faint">
            {i % 2 === 0 ? d.label : ''}
          </span>
        ))}
      </div>
    </div>
  );
}

