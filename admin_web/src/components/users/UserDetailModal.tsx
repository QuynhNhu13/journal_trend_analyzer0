import { useEffect, useState } from 'react';

import type { AppUser, ReportDoc } from '../../types/models';
import { fetchReportsByUser } from '../../services/usersService';
import { strings } from '../../constants/strings';
import { formatBytes, formatDate, formatDateTime } from '../../lib/format';
import { Avatar } from '../ui/Avatar';
import { Icon } from '../ui/Icon';
import { Modal } from '../ui/Modal';
import { Spinner } from '../ui/Spinner';

/** Read-only field row inside the detail modal. */
function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-baseline justify-between gap-4 py-1.5">
      <span className="text-sm text-muted">{label}</span>
      <span className="text-right text-sm font-semibold text-ink break-all">
        {value}
      </span>
    </div>
  );
}

export function UserDetailModal({
  user,
  onClose,
}: {
  user: AppUser;
  onClose: () => void;
}) {
  const [reports, setReports] = useState<ReportDoc[] | null>(null);
  const [error, setError] = useState(false);

  useEffect(() => {
    let active = true;
    setReports(null);
    setError(false);
    fetchReportsByUser(user.uid)
      .then((r) => {
        if (active) setReports(r);
      })
      .catch(() => {
        if (active) setError(true);
      });
    return () => {
      active = false;
    };
  }, [user.uid]);

  const name = user.displayName ?? user.email ?? user.uid;

  return (
    <Modal title={strings.users.detail.title} onClose={onClose} size="lg">
      <div className="flex items-center gap-4">
        <Avatar name={name} photoUrl={user.photoUrl} size={56} />
        <div className="min-w-0">
          <p className="truncate text-lg font-extrabold text-ink">{name}</p>
          <p className="truncate text-sm text-muted">{user.email ?? '—'}</p>
        </div>
      </div>

      <div className="mt-5 grid gap-5 sm:grid-cols-2">
        <div className="rounded-md border border-hairline p-4">
          <p className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">
            {strings.users.detail.profile}
          </p>
          <Field label={strings.users.detail.uid} value={user.uid} />
          <Field
            label={strings.users.detail.platform}
            value={user.platform ?? '—'}
          />
          <Field label={strings.users.col.created} value={formatDate(user.createdAt)} />
        </div>

        <div className="rounded-md border border-hairline p-4">
          <p className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">
            {strings.users.detail.activity}
          </p>
          <Field
            label={strings.users.col.lastLogin}
            value={formatDateTime(user.lastLoginAt)}
          />
          <Field
            label={strings.users.detail.lastActive}
            value={formatDateTime(user.lastActiveAt)}
          />
          <Field
            label={strings.users.col.searches}
            value={String(user.searchCount)}
          />
          <Field
            label={strings.users.col.exports}
            value={String(user.exportCount)}
          />
        </div>
      </div>

      <div className="mt-5">
        <p className="mb-2 text-sm font-bold text-ink">
          {strings.users.detail.reportsTitle}
        </p>

        {reports === null && !error ? (
          <div className="flex items-center gap-3 py-4 text-sm text-muted">
            <Spinner size={20} />
            {strings.states.loading}
          </div>
        ) : null}

        {error ? (
          <p className="py-3 text-sm text-danger">
            {strings.users.detail.reportsError}
          </p>
        ) : null}

        {reports && reports.length === 0 ? (
          <p className="py-3 text-sm text-muted">{strings.users.detail.noReports}</p>
        ) : null}

        {reports && reports.length > 0 ? (
          <ul className="divide-y divide-hairline rounded-md border border-hairline">
            {reports.map((r) => (
              <li key={r.id} className="flex items-center gap-3 px-3 py-2.5">
                <span className="grid h-8 w-8 shrink-0 place-items-center rounded-md bg-brand-soft text-brand">
                  <Icon name="file" className="h-4 w-4" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold text-ink">
                    {r.topic}
                  </p>
                  <p className="truncate text-xs text-muted">
                    {formatDateTime(r.createdAt)} · {formatBytes(r.sizeBytes)}
                  </p>
                </div>
                {r.downloadUrl ? (
                  <a
                    href={r.downloadUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-canvas hover:text-brand"
                    title={strings.common.open}
                  >
                    <Icon name="external" className="h-[18px] w-[18px]" />
                  </a>
                ) : null}
              </li>
            ))}
          </ul>
        ) : null}
      </div>
    </Modal>
  );
}
