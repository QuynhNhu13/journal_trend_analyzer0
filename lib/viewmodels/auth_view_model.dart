import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase/analytics_service.dart';
import '../firebase/auth_service.dart';
import '../firebase/firebase_bootstrap.dart';

/// ViewModel for authentication. Exposes the current user and sign-in/out
/// actions to the Views. Business logic lives here, not in the UI.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  StreamSubscription<User?>? _sub;

  User? _user;
  bool _busy = false;
  String? _error;

  /// True until the first auth state is known (avoids a Login flash on start).
  bool _initializing = true;

  AuthViewModel() {
    _user = _authService.currentUser;
    if (firebaseReady) {
      _sub = _authService.authStateChanges().listen((user) {
        _user = user;
        _initializing = false;
        _analytics.setUser(user?.uid);
        notifyListeners();
      });
    } else {
      _initializing = false;
    }
  }

  /// Lets you browse the app before Firebase is configured (dev convenience).
  bool _demoMode = false;
  bool get demoMode => _demoMode;
  void enterDemo() {
    _demoMode = true;
    notifyListeners();
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Whether the app should show the main content (real login or demo).
  bool get canEnter => isLoggedIn || _demoMode;
  bool get busy => _busy;
  String? get error => _error;
  bool get initializing => _initializing;
  bool get firebaseAvailable => firebaseReady;

  Future<void> signInWithGoogle() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _analytics.logLogin();
      }
    } on GoogleSignInException catch (e) {
      // User cancelled or a Google-side error.
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _error = 'Đăng nhập Google thất bại: ${e.description ?? e.code.name}';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await _analytics.logLogout();
      await _authService.signOut();
      _demoMode = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
