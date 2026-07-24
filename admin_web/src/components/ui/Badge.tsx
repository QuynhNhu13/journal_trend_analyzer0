import type { ReactNode } from 'react';

type Tone = 'brand' | 'neutral' | 'success' | 'warning' | 'danger';

// Soft tinted background + bold text + rounded pill styling.
const TONES: Record<Tone, string> = {
  brand: 'bg-brand-soft/90 text-brand ring-1 ring-inset ring-brand/20',
  neutral: 'bg-subtle text-muted ring-1 ring-inset ring-hairline',
  success: 'bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-200/60',
  warning: 'bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-200/60',
  danger: 'bg-rose-50 text-rose-700 ring-1 ring-inset ring-rose-200/60',
};

/** Small status pill. */
export function Badge({
  children,
  tone = 'neutral',
}: {
  children: ReactNode;
  tone?: Tone;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-bold ${TONES[tone]}`}
    >
      {children}
    </span>
  );
}

