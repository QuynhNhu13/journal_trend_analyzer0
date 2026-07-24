import { NavLink } from 'react-router-dom';

import { NAV_GROUPS, NAV_ITEMS } from '../../constants/nav';
import { strings } from '../../constants/strings';
import { Icon } from '../ui/Icon';

/**
 * Left navigation rail styled with the app's signature pink theme.
 * Supports a collapsed (icon-only) mode on desktop; the brand header keeps a
 * fixed height so its divider lines up exactly with the Topbar's.
 */
export function Sidebar({
  onNavigate,
  collapsed = false,
  onToggleCollapse,
}: {
  onNavigate?: () => void;
  collapsed?: boolean;
  onToggleCollapse?: () => void;
}) {
  return (
    <div className="flex h-full flex-col border-r border-hairline bg-white/95 backdrop-blur-md">
      {/* Brand Header — h-16 matches the Topbar so both dividers align. */}
      <div
        className={`flex h-16 items-center border-b border-hairline/80 ${
          collapsed ? 'justify-center px-2' : 'gap-2 px-4'
        }`}
      >
        {!collapsed ? (
          <div className="min-w-0 flex-1 leading-tight">
            <p className="truncate text-base font-extrabold tracking-tight text-ink">
              {strings.app.name}
            </p>
            <span className="mt-0.5 inline-block rounded-full bg-brand-soft px-2 py-0.5 text-[10px] font-extrabold text-brand ring-1 ring-pink-200/60">
              {strings.app.adminSuffix}
            </span>
          </div>
        ) : null}
        {onToggleCollapse ? (
          <button
            type="button"
            onClick={onToggleCollapse}
            aria-label={collapsed ? strings.nav.expand : strings.nav.collapse}
            title={collapsed ? strings.nav.expand : strings.nav.collapse}
            className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-muted transition-colors hover:bg-brand-tint hover:text-brand"
          >
            <Icon name={collapsed ? 'chevronRight' : 'chevronLeft'} className="h-4 w-4" />
          </button>
        ) : null}
      </div>

      <nav
        className={`flex-1 space-y-5 overflow-y-auto py-4 ${collapsed ? 'px-2' : 'px-3'}`}
      >
        {NAV_GROUPS.map((group) => {
          const items = NAV_ITEMS.filter((item) => item.group === group);
          if (items.length === 0) return null;
          return (
            <div key={group} className="space-y-1">
              {!collapsed ? (
                <p className="px-3 pb-1 text-label font-bold uppercase tracking-wider text-pink-400">
                  {group}
                </p>
              ) : null}
              {items.map((item) => (
                <NavLink
                  key={item.to}
                  to={item.to}
                  end={item.end}
                  onClick={onNavigate}
                  title={collapsed ? item.label : undefined}
                  className={({ isActive }) =>
                    [
                      'group relative flex items-center rounded-xl text-sm font-semibold transition-all duration-200',
                      collapsed ? 'justify-center px-0 py-2.5' : 'gap-3 px-3.5 py-2.5',
                      isActive
                        ? 'bg-gradient-to-r from-brand via-brand-bright to-pink-500 text-white shadow-md shadow-brand/25'
                        : 'text-body hover:bg-brand-tint hover:text-brand',
                    ].join(' ')
                  }
                >
                  {({ isActive }) => (
                    <>
                      <span
                        className={
                          isActive
                            ? 'text-white'
                            : 'text-faint transition-colors group-hover:text-brand'
                        }
                      >
                        <Icon name={item.icon} className="h-5 w-5 shrink-0" />
                      </span>
                      {!collapsed ? <span>{item.label}</span> : null}
                      {!collapsed && isActive ? (
                        <span className="ml-auto h-1.5 w-1.5 rounded-full bg-white shadow-sm" />
                      ) : null}
                    </>
                  )}
                </NavLink>
              ))}
            </div>
          );
        })}
      </nav>

      {/* Footer tagline box (hidden when collapsed to keep the rail slim). */}
      {!collapsed ? (
        <div className="p-3">
          <div className="rounded-xl border border-pink-100 bg-gradient-to-r from-pink-50/70 to-rose-50/50 p-3 text-center">
            <p className="text-xs font-medium text-pink-700">{strings.app.tagline}</p>
          </div>
        </div>
      ) : null}
    </div>
  );
}
