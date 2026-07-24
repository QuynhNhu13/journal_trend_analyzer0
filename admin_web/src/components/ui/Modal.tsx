import { useEffect, type ReactNode } from 'react';

import { strings } from '../../constants/strings';
import { Icon } from './Icon';

/**
 * Centered modal dialog with a backdrop. Closes on backdrop click and Escape.
 */
export function Modal({
  title,
  onClose,
  children,
  footer,
  size = 'md',
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
  size?: 'md' | 'lg';
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  const maxWidth = size === 'lg' ? 'max-w-2xl' : 'max-w-md';

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center p-0 sm:items-center sm:p-6">
      <div className="absolute inset-0 bg-ink/40 backdrop-blur-[1px]" onClick={onClose} aria-hidden="true" />
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        className={`relative flex max-h-[90vh] w-full ${maxWidth} flex-col overflow-hidden rounded-t-xl border border-hairline bg-card shadow-pop sm:rounded-xl`}
      >
        <div className="flex items-center justify-between border-b border-hairline px-5 py-3.5">
          <h2 className="text-sm font-semibold text-ink">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label={strings.common.close}
            className="grid h-9 w-9 place-items-center rounded-md text-muted hover:bg-canvas hover:text-ink"
          >
            <Icon name="close" className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-5 py-5">{children}</div>

        {footer ? (
          <div className="flex justify-end gap-3 border-t border-hairline px-5 py-4">
            {footer}
          </div>
        ) : null}
      </div>
    </div>
  );
}
