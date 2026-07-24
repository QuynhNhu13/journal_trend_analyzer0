import { useState } from 'react';
import { Navigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import { strings } from '../constants/strings';
import { Icon } from '../components/ui/Icon';
import { LoadingState } from '../components/ui/StateView';

/**
 * Shown when a signed-in Google account is not present in the `admins` collection.
 */
export function AccessDeniedPage() {
  const { status, user, signOut } = useAuth();
  const [busy, setBusy] = useState(false);

  // Wait for AuthContext to resolve before deciding
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
    <div className="relative grid min-h-screen place-items-center overflow-hidden bg-gradient-to-br from-pink-50 via-rose-50/40 to-pink-100/50 px-6 py-12">
      <div className="w-full max-w-md rounded-3xl border border-pink-100/80 bg-white/95 p-8 text-center shadow-2xl shadow-pink-500/10 backdrop-blur-xl sm:p-10">
        
        {/* App logo container with shield icon overlay */}
        <div className="relative mx-auto mb-5 flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-br from-pink-100 to-rose-50 p-1.5 shadow-md shadow-brand/20 ring-4 ring-white">
          <img
            src="/logo.png"
            alt="Journal Trend Analyzer Logo"
            className="h-full w-full rounded-xl object-cover opacity-80"
          />
          <span className="absolute -bottom-2 -right-2 grid h-8 w-8 place-items-center rounded-full bg-danger text-white shadow-md">
            <Icon name="shield" className="h-4.5 w-4.5" />
          </span>
        </div>

        <h1 className="mt-4 text-xl font-extrabold text-ink tracking-tight">
          {strings.accessDenied.title}
        </h1>
        <p className="mt-2 text-xs leading-relaxed text-muted">
          {strings.accessDenied.message}
        </p>

        {user?.email ? (
          <p className="mt-4 inline-block rounded-full bg-pink-50 px-3.5 py-1 text-xs font-bold text-brand ring-1 ring-pink-200/60">
            {user.email}
          </p>
        ) : null}

        <button
          type="button"
          onClick={handleSignOut}
          disabled={busy}
          className="mt-8 flex w-full items-center justify-center gap-2 rounded-2xl border border-danger/30 bg-white px-4 py-3 text-xs font-extrabold text-danger shadow-xs transition-all hover:bg-danger/5 disabled:opacity-60"
        >
          <Icon name="logout" className="h-4 w-4" />
          {busy ? strings.auth.signingOut : strings.accessDenied.signOut}
        </button>
      </div>
    </div>
  );
}

