import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'crashlytics_service.dart';
import 'firebase_bootstrap.dart';

/// Writes lightweight user-activity data to Cloud Firestore so the web admin
/// dashboard has something to read (Phase 2).
///
/// Design rules (see lab Phase 2, Part A):
///  - Every write is best-effort and asynchronous: callers `unawaited(...)` it
///    so it never blocks the sign-in / search / export flows.
///  - No method ever throws — failures are reported to Crashlytics only, so a
///    Firestore hiccup can't break the user experience.
///  - All writes use `SetOptions(merge: true)` to avoid clobbering existing data.
///
/// Collections written:
///  - `users/{uid}`      : profile + counters (searchCount, exportCount).
///  - `reports/{autoId}` : one document per successful PDF export.
class UserDataService {
  UserDataService._();
  static final UserDataService instance = UserDataService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Platform tag stored on the user document ("android" on device).
  String get _platform => kIsWeb ? 'web' : defaultTargetPlatform.name;

  /// Whether Firestore writes are possible right now.
  bool get _ready => firebaseReady && FirebaseAuth.instance.currentUser != null;

  /// Upserts `users/{uid}` on sign-in. `createdAt` and the counters are only set
  /// the first time (inside a transaction so concurrent logins can't double-init
  /// or reset them); `lastLoginAt` and the profile fields refresh every time.
  Future<void> recordLogin(User user) async {
    if (!firebaseReady) return;
    final ref = _db.collection('users').doc(user.uid);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = <String, dynamic>{
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'platform': _platform,
          'lastLoginAt': FieldValue.serverTimestamp(),
        };
        if (!snap.exists) {
          data['createdAt'] = FieldValue.serverTimestamp();
          data['searchCount'] = 0;
          data['exportCount'] = 0;
        }
        tx.set(ref, data, SetOptions(merge: true));
      });
    } catch (e, s) {
      await CrashlyticsService.instance
          .recordError(e, s, reason: 'recordLogin failed');
    }
  }

  /// Increments `searchCount` and refreshes `lastActiveAt` on a successful search.
  Future<void> recordSearch() async {
    if (!_ready) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await _db.collection('users').doc(uid).set(
        {
          'searchCount': FieldValue.increment(1),
          'lastActiveAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, s) {
      await CrashlyticsService.instance
          .recordError(e, s, reason: 'recordSearch failed');
    }
  }

  /// Increments `exportCount`, refreshes `lastActiveAt`, and appends a document
  /// to the `reports` collection on a successful PDF export.
  Future<void> recordExport({
    required String topic,
    required String fileName,
    required String downloadUrl,
  }) async {
    if (!_ready) return;
    final user = FirebaseAuth.instance.currentUser!;
    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'exportCount': FieldValue.increment(1),
          'lastActiveAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await _db.collection('reports').add({
        'uid': user.uid,
        'email': user.email,
        'topic': topic,
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      await CrashlyticsService.instance
          .recordError(e, s, reason: 'recordExport failed');
    }
  }
}
