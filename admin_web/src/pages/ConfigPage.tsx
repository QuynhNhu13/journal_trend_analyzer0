import { PageHeader } from '../components/ui/PageHeader';
import { PlaceholderSection } from '../components/ui/PlaceholderSection';
import { strings } from '../constants/strings';

export function ConfigPage() {
  return (
    <div>
      <PageHeader
        title={strings.pages.config.title}
        subtitle={strings.pages.config.subtitle}
      />
      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-8 sm:py-8">
        <PlaceholderSection icon="sliders" title={strings.nav.config} />
      </div>
    </div>
  );
}
