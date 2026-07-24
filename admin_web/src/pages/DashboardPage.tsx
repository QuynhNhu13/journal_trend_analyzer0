import { useCallback, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { Avatar } from '../components/ui/Avatar';
import { Icon } from '../components/ui/Icon';
import { SectionTitle } from '../components/ui/SectionTitle';
import { StatCard } from '../components/ui/StatCard';
import { BarChart } from '../components/ui/BarChart';
import { Skeleton } from '../components/ui/Skeleton';
import { ErrorState } from '../components/ui/StateView';
import { strings } from '../constants/strings';
import { formatDateTime } from '../lib/format';
import type { OverviewData } from '../types/models';
import { fetchOverview } from '../services/overviewService';

const nf = new Intl.NumberFormat('en-US');

const PROJECT_ID = import.meta.env.VITE_FIREBASE_PROJECT_ID;
const CONSOLE_BASE = `https://console.firebase.google.com/project/${PROJECT_ID}`;

interface MonitorLink {
  href: string;
  title: string;
  description: string;
}

function MonitoringCard({ links }: { links: MonitorLink[] }) {
  return (
    <Card>
      <SectionTitle icon="alert" title={strings.overview.monitoringTitle} />
      <p className="mt-2 pl-11 text-xs font-medium text-muted">{strings.overview.monitoringNote}</p>
      <div className="mt-5 grid gap-4 sm:grid-cols-2">
        {links.map((link) => (
          <a
            key={link.href}
            href={link.href}
            target="_blank"
            rel="noreferrer"
            className="group flex items-start gap-3.5 rounded-2xl border border-pink-100/90 bg-white p-4.5 transition-all duration-200 hover:border-pink-300 hover:bg-brand-tint/30 hover:shadow-soft"
          >
            <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-gradient-to-br from-pink-50 to-rose-100/60 text-brand shadow-xs transition-transform group-hover:scale-105">
              <Icon name="external" className="h-5 w-5" />
            </span>
            <div className="min-w-0 flex-1">
              <div className="flex items-center justify-between gap-2">
                <p className="font-extrabold text-ink group-hover:text-brand transition-colors text-sm">{link.title}</p>
                <Icon
                  name="external"
                  className="h-4 w-4 text-faint transition group-hover:text-brand"
                />
              </div>
              <p className="mt-1 text-xs text-muted leading-relaxed">{link.description}</p>
              <p className="mt-2 text-xs font-bold text-brand group-hover:underline">
                {strings.overview.openConsole} &rarr;
              </p>
            </div>
          </a>
        ))}
      </div>
    </Card>
  );
}

export function DashboardPage() {
  const [data, setData] = useState<OverviewData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      setData(await fetchOverview());
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const hasExports = data?.exportsByDay.some((d) => d.count > 0) ?? false;

  return (
    <div>
      <PageHeader
        title={strings.pages.dashboard.title}
        subtitle={strings.pages.dashboard.subtitle}
      />

      <div className="mx-auto max-w-6xl space-y-6 px-4 py-6 sm:px-8 sm:py-8">
        {error ? (
          <Card>
            <ErrorState
              message={strings.overview.errorMessage}
              onRetry={() => void load()}
            />
          </Card>
        ) : loading ? (
          <>
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              {Array.from({ length: 4 }).map((_, i) => (
                <Skeleton key={i} className="h-[92px]" />
              ))}
            </div>
            <Skeleton className="h-64" />
          </>
        ) : data ? (
          <>
            {/* KPIs */}
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <StatCard
                icon="users"
                label={strings.overview.kpiUsers}
                value={nf.format(data.totalUsers)}
              />
              <StatCard
                icon="spark"
                label={strings.overview.kpiActive}
                value={nf.format(data.activeUsers7d)}
              />
              <StatCard
                icon="dashboard"
                label={strings.overview.kpiSearches}
                value={nf.format(data.totalSearches)}
              />
              <StatCard
                icon="file"
                label={strings.overview.kpiReports}
                value={nf.format(data.totalReports)}
              />
            </div>

            {/* Exports chart */}
            <Card>
              <SectionTitle icon="dashboard" title={strings.overview.chartTitle} />
              <p className="mt-1 pl-12 text-xs text-muted">
                {strings.overview.chartSubtitle}
              </p>
              <div className="mt-5">
                {hasExports ? (
                  <BarChart data={data.exportsByDay} />
                ) : (
                  <p className="py-10 text-center text-sm text-muted">
                    {strings.overview.chartEmpty}
                  </p>
                )}
              </div>
            </Card>

            {/* Recent activity */}
            <div className="grid gap-6 lg:grid-cols-2">
              {/* Recent logins */}
              <Card>
                <SectionTitle
                  icon="users"
                  title={strings.overview.recentUsers}
                  trailing={
                    <Link
                      to="/users"
                      className="text-xs font-bold text-brand hover:underline"
                    >
                      {strings.common.viewAll}
                    </Link>
                  }
                />
                <div className="mt-4">
                  {data.recentUsers.length === 0 ? (
                    <p className="py-6 text-center text-sm text-muted">
                      {strings.overview.recentUsersEmpty}
                    </p>
                  ) : (
                    <ul className="divide-y divide-hairline">
                      {data.recentUsers.map((u) => (
                        <li key={u.uid}>
                          <Link
                            to="/users"
                            className="flex items-center gap-3 py-2.5 transition hover:opacity-80"
                          >
                            <Avatar
                              name={u.displayName ?? u.email}
                              photoUrl={u.photoUrl}
                              size={36}
                            />
                            <div className="min-w-0 flex-1">
                              <p className="truncate text-sm font-semibold text-ink">
                                {u.displayName ?? u.email ?? u.uid}
                              </p>
                              <p className="truncate text-xs text-muted">
                                {formatDateTime(u.lastLoginAt)}
                              </p>
                            </div>
                            <Icon
                              name="chevronRight"
                              className="h-4 w-4 shrink-0 text-faint"
                            />
                          </Link>
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
              </Card>

              {/* Recent reports */}
              <Card>
                <SectionTitle
                  icon="file"
                  title={strings.overview.recentReports}
                  trailing={
                    <Link
                      to="/reports"
                      className="text-xs font-bold text-brand hover:underline"
                    >
                      {strings.common.viewAll}
                    </Link>
                  }
                />
                <div className="mt-4">
                  {data.recentReports.length === 0 ? (
                    <p className="py-6 text-center text-sm text-muted">
                      {strings.overview.recentReportsEmpty}
                    </p>
                  ) : (
                    <ul className="divide-y divide-hairline">
                      {data.recentReports.map((r) => (
                        <li key={r.id}>
                          <Link
                            to="/reports"
                            className="flex items-center gap-3 py-2.5 transition hover:opacity-80"
                          >
                            <span className="grid h-9 w-9 shrink-0 place-items-center rounded-md bg-subtle text-muted">
                              <Icon name="file" className="h-[18px] w-[18px]" />
                            </span>
                            <div className="min-w-0 flex-1">
                              <p className="truncate text-sm font-semibold text-ink">
                                {r.topic}
                              </p>
                              <p className="truncate text-xs text-muted">
                                {r.email ?? '—'} · {formatDateTime(r.createdAt)}
                              </p>
                            </div>
                            <Icon
                              name="chevronRight"
                              className="h-4 w-4 shrink-0 text-faint"
                            />
                          </Link>
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
              </Card>
            </div>
          </>
        ) : null}

        {/* Advanced monitoring — deep links to Firebase Console (Part F). */}
        <MonitoringCard
          links={[
            {
              href: `${CONSOLE_BASE}/crashlytics`,
              title: strings.overview.crashlyticsCard,
              description: strings.overview.crashlyticsDesc,
            },
            {
              href: `${CONSOLE_BASE}/analytics/app/android:com.example.journal_trend_analyzer/debugview`,
              title: strings.overview.analyticsCard,
              description: strings.overview.analyticsDesc,
            },
          ]}
        />
      </div>
    </div>
  );
}
