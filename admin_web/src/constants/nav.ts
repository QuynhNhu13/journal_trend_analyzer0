import { strings } from './strings';

/** A single sidebar navigation entry. `icon` is a Lucide-free inline key. */
export interface NavItem {
  /** Router path (also used as the React key). */
  to: string;
  /** Sidebar label. */
  label: string;
  /** Icon identifier resolved by <NavIcon />. */
  icon: NavIconName;
  /** Whether the route should match exactly (used for the index route "/"). */
  end?: boolean;
}

export type NavIconName =
  | 'dashboard'
  | 'users'
  | 'bell'
  | 'sliders'
  | 'file';

export const NAV_ITEMS: readonly NavItem[] = [
  { to: '/', label: strings.nav.dashboard, icon: 'dashboard', end: true },
  { to: '/users', label: strings.nav.users, icon: 'users' },
  { to: '/notifications', label: strings.nav.notifications, icon: 'bell' },
  { to: '/config', label: strings.nav.config, icon: 'sliders' },
  { to: '/reports', label: strings.nav.reports, icon: 'file' },
] as const;
