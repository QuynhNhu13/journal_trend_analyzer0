import type { UserRecord } from 'firebase-admin/auth';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { assertAdmin, loadAdminEmails } from './lib/assertAdmin';
import { adminAuth, bucket, db, REGION } from './lib/firebase';
import { writeAdminLog } from './lib/logs';

interface AuthUserView {
  uid: string;
  email: string | null;
  displayName: string | null;
  photoUrl: string | null;
  disabled: boolean;
  isAdmin: boolean;
  /** True when the account exists in Auth but has no `users/{uid}` profile. */
  hasProfile: boolean;
  creationTime: string | null;
  lastSignInTime: string | null;
  searchCount: number;
  exportCount: number;
}

/** Safety cap — plenty for this project; pagination token is returned if hit. */
const LIST_PAGE = 1000;

function numberField(value: unknown): number {
  return typeof value === 'number' && Number.isFinite(value) ? value : 0;
}

/**
 * Lists Firebase Auth users and reconciles them with their Firestore profile,
 * flagging accounts that exist in Auth but are missing a `users/{uid}` document.
 */
export const listAuthUsers = onCall({ region: REGION }, async (request) => {
  await assertAdmin(request);

  const [listResult, adminEmails] = await Promise.all([
    adminAuth.listUsers(LIST_PAGE),
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
    return {
      uid: u.uid,
      email: u.email ?? null,
      displayName: u.displayName ?? null,
      photoUrl: u.photoURL ?? null,
      disabled: u.disabled,
      isAdmin: u.email ? adminEmails.has(u.email) : false,
      hasProfile,
      creationTime: u.metadata.creationTime ?? null,
      lastSignInTime: u.metadata.lastSignInTime ?? null,
      searchCount: numberField(profile?.get('searchCount')),
      exportCount: numberField(profile?.get('exportCount')),
    };
  });

  return { users, nextPageToken: listResult.pageToken ?? null };
});

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

    await adminAuth.updateUser(uid, { disabled });
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
