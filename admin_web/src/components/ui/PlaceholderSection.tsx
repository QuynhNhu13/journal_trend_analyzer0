import { strings } from '../../constants/strings';
import { Icon, type IconName } from './Icon';
import { Card } from './Card';
import { SectionTitle } from './SectionTitle';

/**
 * Standard "to be built later" panel used by every phase-2 route. Follows the
 * app's card pattern (icon square + title) so placeholders still look branded.
 */
export function PlaceholderSection({
  icon,
  title,
}: {
  icon: IconName;
  title: string;
}) {
  return (
    <Card>
      <SectionTitle
        icon={icon}
        title={title}
        trailing={
          <span className="rounded-full bg-brand-soft px-3 py-1 text-xs font-bold text-brand">
            {strings.placeholder.badge}
          </span>
        }
      />
      <div className="mt-6 grid place-items-center rounded-md border border-dashed border-hairline bg-canvas/60 px-6 py-14 text-center">
        <span className="grid h-16 w-16 place-items-center rounded-full bg-brand-soft text-brand">
          <Icon name="spark" className="h-8 w-8" />
        </span>
        <h3 className="mt-4 text-lg font-bold text-ink">
          {strings.placeholder.title}
        </h3>
        <p className="mt-2 max-w-md text-sm text-muted">
          {strings.placeholder.message}
        </p>
      </div>
    </Card>
  );
}
