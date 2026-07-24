import { strings } from './strings';

/** A single sidebar navigation entry. `icon` is a Lucide-free inline key. */
export interface NavItem {
  /** Router path (also used as the React key). */
  to: string;
  /** Sidebar label. */
  label: string;
  /** Icon identifier resolved by <NavIcon />. */
  icon: NavIconName;
  /** Group label the item is listed under. */
  group: string;
  /** Whether the route should match exactly (used for the index route "/"). */
  end?: boolean;
}

/** Sidebar group order. */
export const NAV_GROUPS: readonly string[] = [
  strings.nav.groupOverview,
  strings.nav.groupServices,
  strings.nav.groupSystem,
] as const;

export type NavIconName =
  | 'dashboard'
  | 'users'
  | 'bell'
  | 'sliders'
  | 'file'
  | 'list'
  | 'database'
  | 'harddrive';

export const NAV_ITEMS: readonly NavItem[] = [
  { to: '/', label: strings.nav.dashboard, icon: 'dashboard', group: strings.nav.groupOverview, end: true },
  { to: '/users', label: strings.nav.users, icon: 'users', group: strings.nav.groupServices },
  { to: '/notifications', label: strings.nav.notifications, icon: 'bell', group: strings.nav.groupServices },
  { to: '/config', label: strings.nav.config, icon: 'sliders', group: strings.nav.groupServices },
  { to: '/database', label: strings.nav.database, icon: 'database', group: strings.nav.groupServices },
  { to: '/storage', label: strings.nav.storage, icon: 'harddrive', group: strings.nav.groupServices },
  { to: '/logs', label: strings.nav.logs, icon: 'list', group: strings.nav.groupSystem },
] as const;
