import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// Wraps Firebase Crashlytics (lab §4.8 "Crashlytics Demo").
/// Crashlytics is not supported on Flutter web, so every call is a no-op there.
class CrashlyticsService {
  CrashlyticsService._();
  static final CrashlyticsService instance = CrashlyticsService._();

  FirebaseCrashlytics? get _c =>
      (firebaseReady && !kIsWeb) ? FirebaseCrashlytics.instance : null;

  /// Records a non-fatal, handled exception.
  Future<void> logHandledException() async {
    try {
      throw StateError('Đây là một handled exception mẫu cho Crashlytics.');
    } catch (e, stack) {
      await _c?.recordError(e, stack, reason: 'Handled exception demo');
      debugPrint('🐞 Handled exception đã gửi tới Crashlytics.');
    }
  }

  /// Forces a fatal crash to test Crashlytics crash reporting.
  /// The app will terminate; the crash appears in the Console shortly after.
  void forceCrash() {
    if (_c == null) return;
    FirebaseCrashlytics.instance.crash();
  }

  Future<void> log(String message) async {
    await _c?.log(message);
  }
}
