import type { ReactNode } from 'react';
import { Navigate } from 'react-router-dom';

import { useAuth } from '../context/AuthContext';
import { strings } from '../constants/strings';
import { LoadingState } from './ui/StateView';

/**
 * Route guard for the authenticated area.
 *  - While auth/admin status is resolving, shows a full-screen spinner (never
 *    flashes the login screen first).
 *  - Not signed in       -> redirect to /login.
 *  - Signed in, not admin -> redirect to /access-denied.
 *  - Signed in admin      -> render children.
 */
export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { status } = useAuth();

  if (status === 'loading') {
    return (
      <div className="grid min-h-screen place-items-center bg-canvas">
        <LoadingState message={strings.auth.checking} />
      </div>
    );
  }

  if (status === 'unauthenticated') {
    return <Navigate to="/login" replace />;
  }

  if (status === 'unauthorized') {
    return <Navigate to="/access-denied" replace />;
  }

  return <>{children}</>;
}
