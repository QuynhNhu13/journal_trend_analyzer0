import { PageHeader } from '../components/ui/PageHeader';
import { PlaceholderSection } from '../components/ui/PlaceholderSection';
import { strings } from '../constants/strings';

export function ReportsPage() {
  return (
    <div>
      <PageHeader
        title={strings.pages.reports.title}
        subtitle={strings.pages.reports.subtitle}
      />
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-8 sm:py-8">
        <PlaceholderSection icon="file" title={strings.nav.reports} />
      </div>
    </div>
  );
}
