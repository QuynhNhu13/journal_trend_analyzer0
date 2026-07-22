import { useCallback, useEffect, useMemo, useState } from 'react';

import { PageHeader } from '../components/ui/PageHeader';
import { Card } from '../components/ui/Card';
import { Avatar } from '../components/ui/Avatar';
import { Badge } from '../components/ui/Badge';
import { Icon } from '../components/ui/Icon';
import { TableSkeleton } from '../components/ui/Skeleton';
import { EmptyState, ErrorState } from '../components/ui/StateView';
import { UserDetailModal } from '../components/users/UserDetailModal';
import { strings } from '../constants/strings';
import { formatDate, formatDateTime } from '../lib/format';
import type { AppUser, UserSortField } from '../types/models';
import {
  fetchUsersPage,
  type UserCursor,
} from '../services/usersService';

const PAGE_SIZE = 25;

export function UsersPage() {
  const [users, setUsers] = useState<AppUser[]>([]);
  const [cursor, setCursor] = useState<UserCursor | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState(false);
  const [sortBy, setSortBy] = useState<UserSortField>('lastLoginAt');
  const [searchText, setSearchText] = useState('');
  const [selected, setSelected] = useState<AppUser | null>(null);

  const loadFirstPage = useCallback(async () => {
    setLoading(true);
    setError(false);
    try {
      const page = await fetchUsersPage({ sortBy, pageSize: PAGE_SIZE });
      setUsers(page.users);
      setCursor(page.cursor);
      setHasMore(page.hasMore);
    } catch {
      setError(true);
    } finally {
      setLoading(false);
    }
  }, [sortBy]);

  useEffect(() => {
    void loadFirstPage();
  }, [loadFirstPage]);

  const loadMore = async () => {
    if (!cursor || loadingMore) return;
    setLoadingMore(true);
    try {
      const page = await fetchUsersPage({ sortBy, pageSize: PAGE_SIZE, cursor });
      setUsers((prev) => [...prev, ...page.users]);
      setCursor(page.cursor);
      setHasMore(page.hasMore);
    } catch {
      setError(true);
    } finally {
      setLoadingMore(false);
    }
  };

  const filtered = useMemo(() => {
    const q = searchText.trim().toLowerCase();
    if (!q) return users;
    return users.filter(
      (u) =>
        (u.displayName ?? '').toLowerCase().includes(q) ||
        (u.email ?? '').toLowerCase().includes(q),
    );
  }, [users, searchText]);

  return (
    <div>
      <PageHeader
        title={strings.pages.users.title}
        subtitle={strings.pages.users.subtitle}
      />

      <div className="mx-auto max-w-6xl px-4 py-6 sm:px-8 sm:py-8">
        <Card className="!p-0">
          {/* Toolbar */}
          <div className="flex flex-col gap-3 border-b border-hairline p-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative sm:w-80">
              <Icon
                name="users"
                className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-faint"
              />
              <input
                type="text"
                value={searchText}
                onChange={(e) => setSearchText(e.target.value)}
                placeholder={strings.users.searchPlaceholder}
                className="w-full rounded-md border border-hairline bg-canvas py-2.5 pl-9 pr-3 text-sm text-ink outline-none placeholder:text-faint focus:border-brand focus:bg-card"
              />
            </div>

            <div className="flex items-center gap-2">
              <label className="text-xs font-semibold text-muted">
                {strings.users.sortLabel}
              </label>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as UserSortField)}
                className="rounded-md border border-hairline bg-card py-2 pl-3 pr-8 text-sm font-semibold text-ink outline-none focus:border-brand"
              >
                <option value="lastLoginAt">{strings.users.sortLastLogin}</option>
                <option value="createdAt">{strings.users.sortCreated}</option>
              </select>
            </div>
          </div>

          {/* Body */}
          {loading ? (
            <TableSkeleton rows={6} columns={5} />
          ) : error ? (
            <ErrorState
              message={strings.users.errorMessage}
              onRetry={() => void loadFirstPage()}
            />
          ) : users.length === 0 ? (
            <EmptyState
              icon="users"
              title={strings.users.emptyTitle}
              message={strings.users.emptyMessage}
            />
          ) : filtered.length === 0 ? (
            <EmptyState icon="users" title={strings.users.noMatch} />
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full min-w-[720px] border-collapse text-left">
                  <thead>
                    <tr className="border-b border-hairline text-xs font-bold uppercase tracking-wide text-muted">
                      <th className="px-4 py-3">{strings.users.col.user}</th>
                      <th className="px-4 py-3">{strings.users.col.email}</th>
                      <th className="px-4 py-3">{strings.users.col.created}</th>
                      <th className="px-4 py-3">{strings.users.col.lastLogin}</th>
                      <th className="px-4 py-3 text-center">
                        {strings.users.col.searches}
                      </th>
                      <th className="px-4 py-3 text-center">
                        {strings.users.col.exports}
                      </th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-hairline">
                    {filtered.map((u) => (
                      <tr
                        key={u.uid}
                        onClick={() => setSelected(u)}
                        className="cursor-pointer transition hover:bg-brand-soft/40"
                      >
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <Avatar
                              name={u.displayName ?? u.email}
                              photoUrl={u.photoUrl}
                              size={36}
                            />
                            <span className="font-semibold text-ink">
                              {u.displayName ?? '—'}
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-3 text-sm text-body">
                          {u.email ?? '—'}
                        </td>
                        <td className="px-4 py-3 text-sm text-muted">
                          {formatDate(u.createdAt)}
                        </td>
                        <td className="px-4 py-3 text-sm text-muted">
                          {formatDateTime(u.lastLoginAt)}
                        </td>
                        <td className="px-4 py-3 text-center">
                          <Badge tone="neutral">{u.searchCount}</Badge>
                        </td>
                        <td className="px-4 py-3 text-center">
                          <Badge>{u.exportCount}</Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="flex items-center justify-between gap-3 border-t border-hairline p-4">
                <span className="text-xs text-muted">
                  {strings.users.countLabel(users.length)}
                </span>
                {hasMore && !searchText ? (
                  <button
                    type="button"
                    onClick={() => void loadMore()}
                    disabled={loadingMore}
                    className="rounded-md border border-hairline px-4 py-2 text-sm font-semibold text-body transition hover:border-brand hover:text-brand disabled:opacity-60"
                  >
                    {loadingMore ? strings.states.loading : strings.common.loadMore}
                  </button>
                ) : null}
              </div>
            </>
          )}
        </Card>
      </div>

      {selected ? (
        <UserDetailModal user={selected} onClose={() => setSelected(null)} />
      ) : null}
    </div>
  );
}
