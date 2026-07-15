import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

/// Wraps Firebase Authentication + Google Sign-In.
///
/// This is the **Service** layer (no UI, no state). The ViewModel
/// ([AuthViewModel]) talks to this class and exposes state to the Views.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => firebaseReady ? _auth.currentUser : null;

  /// Stream of auth state changes (used by the auth gate).
  Stream<User?> authStateChanges() =>
      firebaseReady ? _auth.authStateChanges() : const Stream.empty();

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    // On Android the plugin reads `default_web_client_id` (generated from
    // google-services.json), so we don't need to pass serverClientId manually.
    await _googleSignIn.initialize();
    _googleInitialized = true;
  }

  /// Signs in with Google and links the credential to Firebase Auth.
  /// Returns the signed-in [User], or null if the user cancelled.
  Future<User?> signInWithGoogle() async {
    if (!firebaseReady) {
      throw StateError(
        'Firebase chưa cấu hình. Hãy hoàn tất FIREBASE_SETUP.md.',
      );
    }

    // On web, use Firebase Auth's popup flow (no SHA-1 / native plugin needed).
    if (kIsWeb) {
      final cred = await _auth.signInWithPopup(GoogleAuthProvider());
      return cred.user;
    }

    await _ensureGoogleInitialized();

    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    final String? idToken = account.authentication.idToken;

    if (idToken == null) {
      throw StateError(
        'Không lấy được idToken từ Google. Kiểm tra SHA-1 đã đăng ký trên '
        'Firebase Console (xem FIREBASE_SETUP.md, Bước 4).',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  /// Signs out from both Google and Firebase.
  Future<void> signOut() async {
    if (!firebaseReady) return;
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out errors; still sign out of Firebase.
    }
    await _auth.signOut();
  }
}
