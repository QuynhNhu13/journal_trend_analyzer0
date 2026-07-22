import { useState } from 'react';
import { Navigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import { strings } from '../constants/strings';
import { Icon } from '../components/ui/Icon';
import { Spinner } from '../components/ui/Spinner';

/**
 * Google Sign-In entry point. Mirrors the app's login screen: full-bleed brand
 * gradient, white logo tile, and a white Google button.
 */
export function LoginPage() {
  const { status, signInWithGoogle } = useAuth();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
    <div className="grid min-h-screen place-items-center bg-brand px-6 py-12">
      <div className="w-full max-w-md text-center">
        <div className="mx-auto grid h-24 w-24 place-items-center rounded-xl bg-white shadow-soft">
          <Icon name="spark" className="h-12 w-12 text-brand" />
        </div>

        <h1 className="mt-7 text-3xl font-extrabold tracking-tight text-white">
          {strings.app.name}
        </h1>
        <p className="mt-1 text-sm font-semibold text-white/90">
          {strings.login.title}
        </p>
        <p className="mx-auto mt-3 max-w-sm text-sm leading-relaxed text-white/80">
          {strings.login.subtitle}
        </p>

        <div className="mt-9">
          <button
            type="button"
            onClick={handleSignIn}
            disabled={busy}
            className="flex h-14 w-full items-center justify-center gap-3 rounded-md bg-white text-[15px] font-bold text-ink shadow-soft transition hover:bg-white/95 disabled:opacity-70"
          >
            {busy ? (
              <>
                <Spinner size={22} className="border-brand" />
                <span>{strings.login.signingIn}</span>
              </>
            ) : (
              <>
                <Icon name="google" className="h-6 w-6" />
                <span>{strings.login.googleButton}</span>
              </>
            )}
          </button>

          {error ? (
            <div className="mt-4 rounded-sm bg-white/15 px-4 py-3 text-sm text-white">
              {error}
            </div>
          ) : null}
        </div>

        <p className="mt-10 flex items-center justify-center gap-2 text-xs text-white/70">
          <Icon name="lock" className="h-4 w-4" />
          {strings.login.poweredBy}
        </p>
      </div>
    </div>
  );
}
