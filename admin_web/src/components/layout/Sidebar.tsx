import { NavLink } from 'react-router-dom';

import { NAV_ITEMS } from '../../constants/nav';
import { strings } from '../../constants/strings';
import { Icon } from '../ui/Icon';

/**
 * Left navigation rail. The active item is highlighted in brand pink; the rest
 * are neutral gray, matching the app's selected/unselected tab treatment.
 *
 * On small screens the parent renders this inside a slide-in drawer and passes
 * `onNavigate` to close it after a selection.
 */
export function Sidebar({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <div className="flex h-full flex-col bg-card">
      <div className="flex items-center gap-3 px-5 py-5">
        <span className="grid h-10 w-10 place-items-center rounded-md bg-brand text-white shadow-brand">
          <Icon name="spark" className="h-5 w-5" />
        </span>
        <div className="leading-tight">
          <p className="text-sm font-extrabold text-ink">
            {strings.app.name}
          </p>
          <p className="text-xs text-muted">{strings.app.adminSuffix}</p>
        </div>
      </div>

      <nav className="flex-1 space-y-1 px-3 py-2">
        <p className="px-3 pb-1 pt-3 text-[11px] font-bold uppercase tracking-wider text-faint">
          {strings.nav.sectionMain}
        </p>
        {NAV_ITEMS.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.end}
            onClick={onNavigate}
            className={({ isActive }) =>
              [
                'flex items-center gap-3 rounded-md px-3 py-2.5 text-sm font-semibold transition',
                isActive
                  ? 'bg-brand-soft text-brand'
                  : 'text-muted hover:bg-canvas hover:text-ink',
              ].join(' ')
            }
          >
            <Icon name={item.icon} className="h-5 w-5 shrink-0" />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="px-5 py-4">
        <p className="text-[11px] text-faint">{strings.app.tagline}</p>
      </div>
    </div>
  );
}
