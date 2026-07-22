import { useState } from 'react';

import { useAuth } from '../../context/AuthContext';
import { strings } from '../../constants/strings';
import { Icon } from '../ui/Icon';

/**
 * Top bar: hamburger (mobile only) on the left, admin identity + sign-out on the
 * right. Shows avatar photo when available, else a brand-tinted initial.
 */
export function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  const { user, signOut } = useAuth();
  const [signingOut, setSigningOut] = useState(false);

  const name = user?.displayName ?? user?.email ?? 'Admin';
  const email = user?.email ?? '';
  const initial = (name.trim()[0] ?? 'A').toUpperCase();

  const handleSignOut = async () => {
    setSigningOut(true);
    try {
      await signOut();
    } finally {
      setSigningOut(false);
    }
  };

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between gap-3 border-b border-hairline bg-card/95 px-4 backdrop-blur sm:px-6">
      <button
        type="button"
        onClick={onMenuClick}
        aria-label="Open navigation"
        className="grid h-10 w-10 place-items-center rounded-md text-muted hover:bg-canvas hover:text-ink lg:hidden"
      >
        <Icon name="menu" className="h-5 w-5" />
      </button>

      <div className="ml-auto flex items-center gap-3">
        <div className="hidden text-right sm:block">
          <p className="text-sm font-bold leading-tight text-ink">{name}</p>
          <p className="text-xs leading-tight text-muted">{email}</p>
        </div>

        {user?.photoURL ? (
          <img
            src={user.photoURL}
            alt={name}
            referrerPolicy="no-referrer"
            className="h-10 w-10 rounded-full border border-hairline object-cover"
          />
        ) : (
          <span className="grid h-10 w-10 place-items-center rounded-full bg-brand-soft text-sm font-extrabold text-brand">
            {initial}
          </span>
        )}

        <button
          type="button"
          onClick={handleSignOut}
          disabled={signingOut}
          className="flex items-center gap-2 rounded-md border border-hairline px-3 py-2 text-sm font-semibold text-body transition hover:border-danger/40 hover:text-danger disabled:opacity-60"
        >
          <Icon name="logout" className="h-[18px] w-[18px]" />
          <span className="hidden sm:inline">
            {signingOut ? strings.auth.signingOut : strings.auth.signOut}
          </span>
        </button>
      </div>
    </header>
  );
}
