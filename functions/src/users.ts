import type { UserRecord } from 'firebase-admin/auth';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { assertAdmin, loadAdminEmails } from './lib/assertAdmin';
import { adminAuth, bucket, db, REGION } from './lib/firebase';
import { writeAdminLog } from './lib/logs';
import { wrap } from './lib/wrap';

interface AuthUserView {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  disabled: boolean;
  emailVerified: boolean;
  /** Sign-in providers, e.g. ["google.com"]. */
  providers: string[];
  isAdmin: boolean;
  /** True when the account exists in Auth but has no `users/{uid}` profile. */
  hasProfile: boolean;
  creationTime: string | null;
  lastSignInTime: string | null;
  lastActiveAt: string | null;
  searchCount: number;
  exportCount: number;
  /** Whether an FCM token is stored (never expose the token itself). */
  hasFcmToken: boolean;
  fcmTokenUpdatedAt: string | null;
}

/** Page size for one listUsers call. */
const LIST_PAGE = 1000;

function numberField(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

/** Firestore Timestamp → ISO string (or null). */
function tsToIso(value: unknown): string | null {
  if (
    value &&
    typeof value === 'object' &&
    typeof (value as { toDate?: unknown }).toDate === 'function'
  ) {
    try {
      return (value as { toDate(): Date }).toDate().toISOString();
    } catch {
      return null;
    }
  }
  return null;
}

/**
 * Lists Firebase Auth users and reconciles them with their Firestore profile,
 * flagging accounts that exist in Auth but are missing a `users/{uid}` document.
 */
export const listAuthUsers = onCall<{ pageToken?: string }>(
  { region: REGION },
  async (request) => {
    await assertAdmin(request);

    const pageToken = request.data?.pageToken || undefined;
    const [listResult, adminEmails] = await Promise.all([
      wrap('listUsers (Auth)', () => adminAuth.listUsers(LIST_PAGE, pageToken)),
      loadAdminEmails(),
    ]);

    const records: UserRecord[] = listResult.users;
    const profileSnaps = records.length
      ? await db.getAll(...records.map((u) => db.collection('users').doc(u.uid)))
      : [];
    const profileByUid = new Map(profileSnaps.map((snap) => [snap.id, snap]));

    const users: AuthUserView[] = records.map((u) => {
      const profile = profileByUid.get(u.uid);
      const hasProfile = profile?.exists ?? false;
      const fcmToken = profile?.get('fcmToken');
      return {
        uid: u.uid,
        email: u.email ?? null,
        displayName: u.displayName ?? null,
        photoUrl: u.photoURL ?? null,
        disabled: u.disabled,
        emailVerified: u.emailVerified,
        providers: u.providerData.map((p) => p.providerId),
        isAdmin: u.email ? adminEmails.has(u.email) : false,
        hasProfile,
        creationTime: u.metadata.creationTime ?? null,
        lastSignInTime: u.metadata.lastSignInTime ?? null,
        lastActiveAt: tsToIso(profile?.get('lastActiveAt')),
        searchCount: numberField(profile?.get('searchCount')),
        exportCount: numberField(profile?.get('exportCount')),
        hasFcmToken: typeof fcmToken === 'string' && fcmToken.length > 0,
        fcmTokenUpdatedAt: tsToIso(profile?.get('fcmTokenUpdatedAt')),
      };
    });

    // Operational diagnostic (visible in `firebase functions:log`): distinguishes
    // "Auth returned 0 accounts" from "client dropped a non-empty result".
    console.log(`[listAuthUsers] authCount=${records.length} returned=${users.length}`);

    return { users, nextPageToken: listResult.pageToken ?? null };
  },
);

interface CreateUserData {
  email: string;
  password: string;
  displayName?: string;
}

/** Creates a new Auth account with a temporary password. */
export const createUser = onCall<CreateUserData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { email, password, displayName } = request.data;
    if (!email?.trim() || !password || password.length < 6) {
      throw new HttpsError(
        'invalid-argument',
        'A valid email and a password of at least 6 characters are required.',
      );
    }

    let created;
    try {
      created = await adminAuth.createUser({
        email: email.trim(),
        password,
        displayName: displayName?.trim() || undefined,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Create failed.';
      throw new HttpsError('already-exists', message);
    }

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'createUser',
      targetId: created.uid,
      params: { email: email.trim() },
    });
    return { uid: created.uid };
  },
);

interface UpdateUserData {
  uid: string;
  displayName?: string;
  photoURL?: string;
}

/** Updates a user's display name and/or photo URL. */
export const updateUser = onCall<UpdateUserData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { uid, displayName, photoURL } = request.data;
    if (!uid) throw new HttpsError('invalid-argument', 'A user id is required.');

    await wrap('updateUser', () =>
      adminAuth.updateUser(uid, {
        displayName: displayName?.trim() || undefined,
        photoURL: photoURL?.trim() || undefined,
      }),
    );

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'updateUser',
      targetId: uid,
      params: { displayName: displayName ?? null, photoURL: photoURL ?? null },
    });
    return { uid };
  },
);

interface PasswordResetData {
  email: string;
}

/**
 * Validates that a user exists and records the request; the actual reset email
 * is dispatched from the web via Firebase's built-in `sendPasswordResetEmail`.
 */
export const sendPasswordReset = onCall<PasswordResetData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { email } = request.data;
    if (!email?.trim()) throw new HttpsError('invalid-argument', 'An email is required.');

    try {
      await adminAuth.getUserByEmail(email.trim());
    } catch {
      throw new HttpsError('not-found', 'No user with that email.');
    }

    await writeAdminLog({
      actorEmail: admin.email,
      action: 'sendPasswordReset',
      targetId: email.trim(),
    });
    return { ok: true };
  },
);

interface SetDisabledData {
  uid: string;
  disabled: boolean;
}

/** Locks or unlocks a Firebase Auth account. */
export const setUserDisabled = onCall<SetDisabledData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { uid, disabled } = request.data;
    if (!uid) throw new HttpsError('invalid-argument', 'A user id is required.');
    if (uid === admin.uid) {
      throw new HttpsError('failed-precondition', 'You cannot lock your own account.');
    }

    await writeAdminLog({
      actorEmail: admin.email,
      action: disabled ? 'disableUser' : 'enableUser',
      targetId: uid,
      params: { disabled },
    });

    await wrap('setUserDisabled', () => adminAuth.updateUser(uid, { disabled }));
    return { uid, disabled };
  },
);

interface DeleteUserData {
  uid: string;
}

/**
 * Permanently deletes a user everywhere: their exported report files in Storage,
 * their `reports` documents, their `users/{uid}` profile, and the Auth account.
 * Refuses to delete yourself or another administrator.
 */
export const deleteUser = onCall<DeleteUserData>(
  { region: REGION },
  async (request) => {
    const admin = await assertAdmin(request);
    const { uid } = request.data;
    if (!uid) throw new HttpsError('invalid-argument', 'A user id is required.');
    if (uid === admin.uid) {
      throw new HttpsError('failed-precondition', 'You cannot delete your own account.');
    }

    // Resolve the target's email to protect admin accounts.
    let targetEmail: string | null = null;
    try {
      const record = await adminAuth.getUser(uid);
      targetEmail = record.email ?? null;
    } catch {
      // No Auth record (orphaned profile) — deletion of Firestore data still runs.
    }
    if (targetEmail) {
      const adminEmails = await loadAdminEmails();
      if (adminEmails.has(targetEmail)) {
        throw new HttpsError('failed-precondition', 'You cannot delete an administrator.');
      }
    }

    // Audit BEFORE performing the destructive work.
    await writeAdminLog({
      actorEmail: admin.email,
      action: 'deleteUser',
      targetId: uid,
      params: { email: targetEmail },
    });

    // 1) Delete the user's report documents + their Storage files.
    const reportsSnap = await db.collection('reports').where('uid', '==', uid).get();
    let filesDeleted = 0;
    const b = bucket();
    for (const doc of reportsSnap.docs) {
      const fileName = doc.get('fileName');
      if (typeof fileName === 'string' && fileName.length > 0) {
        try {
          await b.file(`reports/${fileName}`).delete();
          filesDeleted += 1;
        } catch {
          // File already gone — ignore.
        }
      }
    }
    const reportsDeleted = reportsSnap.size;
    const batch = db.batch();
    reportsSnap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();

    // 2) Delete the Firestore profile.
    let profileDeleted = false;
    const profileRef = db.collection('users').doc(uid);
    if ((await profileRef.get()).exists) {
      await profileRef.delete();
      profileDeleted = true;
    }

    // 3) Delete the Auth account (may already be absent for orphans).
    let authDeleted = false;
    try {
      await adminAuth.deleteUser(uid);
      authDeleted = true;
    } catch {
      authDeleted = false;
    }

    return { uid, authDeleted, profileDeleted, reportsDeleted, filesDeleted };
  },
);
