import { useState } from 'react';
import { Navigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import { strings } from '../constants/strings';
import { Icon } from '../components/ui/Icon';
import { Spinner } from '../components/ui/Spinner';

/**
 * Google Sign-In entry point styled in the app's signature pink theme.
 * Displays app logo image prominently with glowing background ambient effects.
 */
export function LoginPage() {
  const { status, signInWithGoogle } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // While auth is still resolving, show a spinner instead of flashing the
  // sign-in UI (which would then immediately redirect on refresh).
  if (status === 'loading') {
    return (
      <div className="grid min-h-screen place-items-center bg-canvas">
        <Spinner size={36} />
      </div>
    );
  }

  // Already resolved sessions skip the login screen.
  if (status === 'authorized') return <Navigate to="/" replace />;
  if (status === 'unauthorized') return <Navigate to="/access-denied" replace />;

  const handleSignIn = async () => {
    setBusy(true);
    setError(null);
    try {
      await signInWithGoogle();
    } catch {
      setError(strings.login.error);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="relative grid min-h-screen place-items-center overflow-hidden bg-gradient-to-br from-pink-50 via-rose-50/50 to-pink-100/40 px-6 py-12">
      {/* Ambient pink background glowing orbs */}
      <div className="pointer-events-none absolute -left-20 -top-20 h-96 w-96 rounded-full bg-pink-300/30 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-20 -right-20 h-96 w-96 rounded-full bg-rose-400/25 blur-3xl" />
      <div className="pointer-events-none absolute left-1/2 top-1/2 h-80 w-80 -translate-x-1/2 -translate-y-1/2 rounded-full bg-brand-soft/50 blur-3xl" />

      <div className="relative z-10 w-full max-w-md">
        <div className="rounded-3xl border border-pink-100/80 bg-white/90 p-8 shadow-2xl shadow-pink-500/10 backdrop-blur-xl sm:p-10 text-center">
          
          {/* Prominent App Logo */}
          <div className="group relative mx-auto mb-6 flex h-24 w-24 items-center justify-center rounded-2xl bg-gradient-to-br from-pink-100 via-rose-50 to-pink-50 p-2 shadow-xl shadow-brand/20 ring-4 ring-white transition-all duration-300 hover:scale-105">
            <img
              src="/logo.png"
              alt="Journal Trend Analyzer App Logo"
              className="h-full w-full rounded-xl object-cover"
            />
            <span className="absolute -bottom-2 -right-2 grid h-7 w-7 place-items-center rounded-full bg-brand text-white shadow-md">
              <Icon name="spark" className="h-4 w-4" />
            </span>
          </div>

          <div className="inline-flex items-center gap-1.5 rounded-full bg-brand-soft px-3 py-1 text-xs font-bold text-brand mb-3">
            <span>{strings.app.adminSuffix}</span>
          </div>

          <h1 className="text-2xl font-extrabold text-ink tracking-tight">
            {strings.app.name}
          </h1>
          <p className="mt-1.5 text-sm font-semibold text-brand">
            {strings.login.title}
          </p>
          <p className="mx-auto mt-2 max-w-xs text-xs leading-relaxed text-muted">
            {strings.login.subtitle}
          </p>

          <button
            type="button"
            onClick={handleSignIn}
            disabled={busy}
            className="mt-8 flex h-12 w-full items-center justify-center gap-3 rounded-2xl border border-pink-200/80 bg-white text-sm font-bold text-ink shadow-md shadow-pink-100 transition-all duration-200 hover:border-brand/40 hover:bg-brand-tint hover:shadow-brand/10 hover:scale-[1.01] active:scale-[0.99] disabled:opacity-70"
          >
            {busy ? (
              <>
                <Spinner size={20} />
                <span>{strings.login.signingIn}</span>
              </>
            ) : (
              <>
                <Icon name="google" className="h-5 w-5" />
                <span>{strings.login.googleButton}</span>
              </>
            )}
          </button>

          {error ? (
            <div className="mt-4 rounded-xl border border-danger/30 bg-danger/5 px-3.5 py-2.5 text-xs font-semibold text-danger">
              {error}
            </div>
          ) : null}
        </div>

        <p className="mt-6 flex items-center justify-center gap-2 text-xs font-medium text-pink-700/70">
          <Icon name="lock" className="h-3.5 w-3.5" />
          {strings.login.poweredBy}
        </p>
      </div>
    </div>
  );
}

