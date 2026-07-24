import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  onAuthStateChanged,
  signInWithPopup,
  signOut as firebaseSignOut,
  type User,
} from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';

import { auth, db, googleProvider } from '../lib/firebase';

/**
 * Authentication + authorization lifecycle:
 *  - 'loading'      : waiting for the first auth state OR checking admin rights
 *  - 'unauthenticated' : no signed-in user
 *  - 'authorized'   : signed in AND present in the `admins` collection
 *  - 'unauthorized' : signed in but NOT an admin
 *
 * Keeping the admin check inside the 'loading' status is what prevents the login
 * screen from flashing before the dashboard renders on refresh.
 */
export type AuthStatus =
  | 'loading'
  | 'unauthenticated'
  | 'authorized'
  | 'unauthorized';

interface AuthContextValue {
  status: AuthStatus;
  user: User | null;
  signInWithGoogle: () => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

/** Reads `admins/{email}`; presence of the document grants admin access. */
async function isAdminEmail(email: string | null): Promise<boolean> {
  if (!email) return false;
  const snapshot = await getDoc(doc(db, 'admins', email));
  return snapshot.exists();
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AuthStatus>('loading');
  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    // Each auth event gets a monotonically increasing id. An awaited admin check
    // only applies its result if no newer event has fired meanwhile, so a check
    // from a previous user (or a signed-out state) can't overwrite the current
    // status.
    let latestEvent = 0;

    const unsubscribe = onAuthStateChanged(auth, async (nextUser) => {
      const event = ++latestEvent;
      setUser(nextUser);

      if (!nextUser) {
        setStatus('unauthenticated');
        return;
      }

      // Re-enter the loading state while we verify admin rights so guards keep
      // showing the spinner instead of briefly rendering the wrong screen.
      setStatus('loading');
      try {
        const allowed = await isAdminEmail(nextUser.email);
        if (event !== latestEvent) return; // superseded by a newer auth event
        setStatus(allowed ? 'authorized' : 'unauthorized');
      } catch {
        // A rules rejection or network error is treated as "not authorized"
        // rather than crashing the app.
        if (event !== latestEvent) return;
        setStatus('unauthorized');
      }
    });

    return unsubscribe;
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      status,
      user,
      signInWithGoogle: async () => {
        await signInWithPopup(auth, googleProvider);
        // onAuthStateChanged drives the admin check and status transition.
      },
      signOut: async () => {
        await firebaseSignOut(auth);
      },
    }),
    [status, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within an <AuthProvider>');
  }
  return ctx;
}
