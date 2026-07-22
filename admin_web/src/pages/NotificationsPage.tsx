import { PageHeader } from '../components/ui/PageHeader';
import { PlaceholderSection } from '../components/ui/PlaceholderSection';
import { strings } from '../constants/strings';

export function NotificationsPage() {
  return (
    <div>
      <PageHeader
        title={strings.pages.notifications.title}
        subtitle={strings.pages.notifications.subtitle}
      />
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-8 sm:py-8">
        <PlaceholderSection icon="bell" title={strings.nav.notifications} />
      </div>
    </div>
  );
}
