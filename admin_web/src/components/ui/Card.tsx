import type { ReactNode } from 'react';

/**
 * Surface card: white, subtle pink hairline border, soft modern shadow, rounded-2xl radius.
 */
export function Card({
  children,
  className = '',
}: {
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={`rounded-2xl border border-pink-100/80 bg-white p-5 shadow-soft transition-all duration-200 hover:shadow-card sm:p-6 ${className}`}>
      {children}
    </div>
  );
}

