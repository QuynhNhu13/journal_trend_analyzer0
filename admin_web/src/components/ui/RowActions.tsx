import { useEffect, useRef, useState } from 'react';

import { Icon, type IconName } from './Icon';

export interface RowAction {
  label: string;
  icon?: IconName;
  onClick: () => void;
  danger?: boolean;
  disabled?: boolean;
}

/**
 * Per-row overflow menu (three-dot). Collapses row actions into a dropdown so
 * tables stay uncluttered. Closes on outside click and Escape.
 */
export function RowActions({ actions }: { actions: RowAction[] }) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setOpen(false);
    };
    document.addEventListener('mousedown', onDoc);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('mousedown', onDoc);
      document.removeEventListener('keydown', onKey);
    };
  }, [open]);

  return (
    <div ref={ref} className="relative inline-block text-left">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-haspopup="menu"
        aria-expanded={open}
        aria-label="Row actions"
        className="grid h-8 w-8 place-items-center rounded-md text-muted transition hover:bg-subtle hover:text-ink"
      >
        <Icon name="more" className="h-[18px] w-[18px]" />
      </button>

      {open ? (
        <div
          role="menu"
          className="absolute right-0 z-20 mt-1 w-44 overflow-hidden rounded-lg border border-hairline bg-card py-1 shadow-pop"
        >
          {actions.map((action) => (
            <button
              key={action.label}
              type="button"
              role="menuitem"
              disabled={action.disabled}
              onClick={() => {
                setOpen(false);
                action.onClick();
              }}
              className={`flex w-full items-center gap-2.5 px-3 py-2 text-left text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-40 ${
                action.danger
                  ? 'text-danger hover:bg-danger/5'
                  : 'text-body hover:bg-subtle'
              }`}
            >
              {action.icon ? <Icon name={action.icon} className="h-4 w-4 shrink-0" /> : null}
              {action.label}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
