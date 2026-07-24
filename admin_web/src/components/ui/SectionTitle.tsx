import type { ReactNode } from 'react';

import { Icon, type IconName } from './Icon';

/**
 * Section heading: a pink gradient icon chip next to a bold title.
 */
export function SectionTitle({
  title,
  icon,
  trailing,
}: {
  title: string;
  icon: IconName;
  trailing?: ReactNode;
}) {
  return (
    <div className="flex items-center gap-3">
      <span className="grid h-8 w-8 place-items-center rounded-xl bg-gradient-to-br from-pink-100 to-rose-50 text-brand shadow-xs">
        <Icon name={icon} className="h-4.5 w-4.5" />
      </span>
      <h2 className="flex-1 text-base font-extrabold text-ink tracking-tight">{title}</h2>
      {trailing}
    </div>
  );
}

