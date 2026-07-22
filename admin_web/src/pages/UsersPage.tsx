import { PageHeader } from '../components/ui/PageHeader';
import { PlaceholderSection } from '../components/ui/PlaceholderSection';
import { strings } from '../constants/strings';

export function UsersPage() {
  return (
    <div>
      <PageHeader
        title={strings.pages.users.title}
        subtitle={strings.pages.users.subtitle}
      />
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-8 sm:py-8">
        <PlaceholderSection icon="users" title={strings.nav.users} />
      </div>
    </div>
  );
}
