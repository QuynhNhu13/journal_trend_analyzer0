import { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';

import { useAuth } from '../../context/AuthContext';
import { NAV_ITEMS } from '../../constants/nav';
import { strings } from '../../constants/strings';
import { Icon } from '../ui/Icon';
import { Avatar } from '../ui/Avatar';
import { useToast } from '../ui/Toast';

/**
 * Topbar with glassmorphism, pink subtle accent border, breadcrumbs and admin badge.
 */
export function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  const { user, signOut } = useAuth();
  const { showToast } = useToast();
  const { pathname } = useLocation();
  const [signingOut, setSigningOut] = useState(false);

  const name = user?.displayName ?? user?.email ?? 'Admin';
  const email = user?.email ?? '';
  const current = NAV_ITEMS.find((i) => i.to === pathname) ?? NAV_ITEMS[0];

  const handleSignOut = async () => {
    setSigningOut(true);
    try {
      await signOut();
    } catch {
      showToast(strings.auth.signOutError, 'error');
    } finally {
      setSigningOut(false);
    }
  };

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-pink-100/70 bg-white/85 px-4 backdrop-blur-md transition-all sm:px-6 shadow-xs">
      <button
        type="button"
        onClick={onMenuClick}
        aria-label="Open navigation"
        className="grid h-9 w-9 place-items-center rounded-xl text-muted hover:bg-brand-tint hover:text-brand transition-colors lg:hidden"
      >
        <Icon name="menu" className="h-5 w-5" />
      </button>

      {/* Breadcrumb */}
      <nav className="flex items-center gap-2 text-sm font-semibold">
        <Link
          to="/"
          className="flex items-center gap-1.5 rounded-lg px-2 py-1 text-muted hover:bg-brand-tint hover:text-brand transition-all"
          aria-label={strings.nav.dashboard}
        >
          <Icon name="home" className="h-4 w-4" />
        </Link>
        <Icon name="chevronRight" className="h-3.5 w-3.5 text-pink-300" />
        <span className="rounded-lg bg-brand-soft/60 px-2.5 py-1 text-brand font-bold text-xs sm:text-sm">
          {current?.label ?? ''}
        </span>
      </nav>

      <div className="ml-auto flex items-center gap-3">
        <div className="hidden text-right sm:block">
          <p className="text-xs font-bold leading-tight text-ink">{name}</p>
          <p className="text-[11px] leading-tight text-muted">{email}</p>
        </div>

        <div className="relative rounded-full ring-2 ring-brand/20 p-0.5 shadow-xs">
          <Avatar name={name} photoUrl={user?.photoURL} size={32} />
        </div>

        <span className="hidden h-7 w-px bg-hairline sm:block" aria-hidden="true" />

        <button
          type="button"
          onClick={handleSignOut}
          disabled={signingOut}
          className="flex items-center gap-2 rounded-xl border border-pink-100 bg-white px-3 py-1.5 text-xs font-bold text-body transition-all hover:border-danger/30 hover:bg-danger/5 hover:text-danger disabled:opacity-60 shadow-xs"
        >
          <Icon name="logout" className="h-3.5 w-3.5" />
          <span className="hidden sm:inline">
            {signingOut ? strings.auth.signingOut : strings.auth.signOut}
          </span>
        </button>
      </div>
    </header>
  );
}

