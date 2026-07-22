import type { ReactNode } from 'react';

import { Icon, type IconName } from './Icon';

/**
 * Icon-in-a-rounded-square + title row — the web twin of the Flutter app's
 * SectionTitle: an accent icon on a tinted square next to a bold heading.
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
      <span className="grid h-9 w-9 place-items-center rounded-md bg-brand-soft text-brand">
        <Icon name={icon} className="h-[18px] w-[18px]" />
      </span>
      <h2 className="flex-1 text-base font-bold text-ink">{title}</h2>
      {trailing}
    </div>
  );
}
