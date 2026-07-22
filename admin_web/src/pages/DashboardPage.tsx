import { Link } from 'react-router-dom';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { Icon, type IconName } from '../components/ui/Icon';
import { useAuth } from '../context/AuthContext';
import { strings } from '../constants/strings';

interface ServiceLink {
  to: string;
  title: string;
  description: string;
  icon: IconName;
}

const SERVICES: readonly ServiceLink[] = [
  {
    to: '/users',
    title: strings.nav.users,
    description: 'Review authenticated app users and their access.',
    icon: 'users',
  },
  {
    to: '/notifications',
    title: strings.nav.notifications,
    description: 'Broadcast Cloud Messaging notifications to the app.',
    icon: 'bell',
  },
  {
    to: '/config',
    title: strings.nav.config,
    description: 'Adjust max_journals_displayed and max_keywords_displayed.',
    icon: 'sliders',
  },
  {
    to: '/reports',
    title: strings.nav.reports,
    description: 'Browse exported PDF reports in Cloud Storage.',
    icon: 'file',
  },
];

export function DashboardPage() {
  const { user } = useAuth();
  const firstName = (user?.displayName ?? 'Admin').split(' ')[0];

  return (
    <div>
      <PageHeader
        title={`${strings.pages.dashboard.title}`}
        subtitle={strings.pages.dashboard.subtitle}
      />

      <div className="mx-auto max-w-6xl space-y-6 px-4 py-6 sm:px-8 sm:py-8">
        <Card>
          <div className="flex items-center gap-4">
            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-md bg-brand-soft text-brand">
              <Icon name="shield" className="h-6 w-6" />
            </span>
            <div>
              <p className="text-lg font-extrabold text-ink">
                Welcome back, {firstName}
              </p>
              <p className="text-sm text-muted">
                You are signed in as {strings.topbar.roleLabel.toLowerCase()}
                {user?.email ? ` · ${user.email}` : ''}.
              </p>
            </div>
          </div>
        </Card>

        <div className="grid gap-4 sm:grid-cols-2">
          {SERVICES.map((service) => (
            <Link
              key={service.to}
              to={service.to}
              className="group rounded-lg border border-hairline bg-card p-5 shadow-soft transition hover:-translate-y-0.5 hover:shadow-brand sm:p-6"
            >
              <div className="flex items-start gap-4">
                <span className="grid h-11 w-11 shrink-0 place-items-center rounded-md bg-brand-soft text-brand">
                  <Icon name={service.icon} className="h-[22px] w-[22px]" />
                </span>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <h3 className="text-base font-bold text-ink">
                      {service.title}
                    </h3>
                    <Icon
                      name="chevronRight"
                      className="h-5 w-5 text-faint transition group-hover:translate-x-0.5 group-hover:text-brand"
                    />
                  </div>
                  <p className="mt-1 text-sm text-muted">{service.description}</p>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
