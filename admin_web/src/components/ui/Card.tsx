import type { ReactNode } from 'react';

/**
 * White rounded card with a hairline border and soft shadow — the web twin of
 * the Flutter app's SectionCard (AppDecorations.card).
 */
export function Card({
  children,
  className = '',
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`rounded-lg border border-hairline bg-card p-5 shadow-soft sm:p-6 ${className}`}
    >
      {children}
    </div>
  );
}
