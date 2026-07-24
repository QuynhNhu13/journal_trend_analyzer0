import { useState } from 'react';
import { Navigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import { strings } from '../constants/strings';
import { Icon } from '../components/ui/Icon';
import { LoadingState } from '../components/ui/StateView';

/**
 * Shown when a signed-in Google account is not present in the `admins`
 * collection. All inner routes are blocked; the only action is signing out.
 */
export function AccessDeniedPage() {
  const { status, user, signOut } = useAuth();
  const [busy, setBusy] = useState(false);

  // Wait for AuthContext to resolve before deciding — otherwise the denial UI
  // flashes before a valid admin is redirected into the dashboard.
  if (status === 'loading') {
    return (
      <div className="grid min-h-screen place-items-center bg-canvas">
        <LoadingState message={strings.auth.checking} />
      </div>
    );
  }

  // If the session isn't actually "signed in but not admin", bounce away.
  if (status === 'unauthenticated') return <Navigate to="/login" replace />;
  if (status === 'authorized') return <Navigate to="/" replace />;

  const handleSignOut = async () => {
    setBusy(true);
    try {
      await signOut();
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="grid min-h-screen place-items-center bg-canvas px-6 py-12">
      <div className="w-full max-w-md rounded-lg border border-hairline bg-card p-8 text-center shadow-soft">
        <span className="mx-auto grid h-20 w-20 place-items-center rounded-full bg-danger/10 text-danger">
          <Icon name="shield" className="h-10 w-10" />
        </span>

        <h1 className="mt-6 text-xl font-extrabold text-ink">
          {strings.accessDenied.title}
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-muted">
          {strings.accessDenied.message}
        </p>

        {user?.email ? (
          <p className="mt-4 inline-block rounded-full bg-canvas px-3 py-1 text-xs font-semibold text-body">
            {user.email}
          </p>
        ) : null}

        <button
          type="button"
          onClick={handleSignOut}
          disabled={busy}
          className="mt-7 flex w-full items-center justify-center gap-2 rounded-md border border-danger/40 px-4 py-3 text-sm font-bold text-danger transition hover:bg-danger/5 disabled:opacity-60"
        >
          <Icon name="logout" className="h-[18px] w-[18px]" />
          {busy ? strings.auth.signingOut : strings.accessDenied.signOut}
        </button>
      </div>
    </div>
  );
}
