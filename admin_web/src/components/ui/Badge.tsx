import type { ReactNode } from 'react';

type Tone = 'brand' | 'neutral' | 'emerald';

const TONES: Record<Tone, string> = {
  brand: 'bg-brand-soft text-brand',
  neutral: 'bg-canvas text-muted',
  emerald: 'bg-emerald/10 text-emerald',
};

/** Small rounded pill for counts, topics, and status tags. */
export function Badge({
  children,
  tone = 'brand',
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
