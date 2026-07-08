import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// Wraps Firebase Remote Config (lab §4.8 "Remote Config Demo").
///
/// Exposes two config values required by the lab:
/// - `max_journals_displayed`
/// - `max_keywords_displayed`
///
/// Falls back to sensible defaults when Firebase is not configured yet.
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  static const String keyMaxJournals = 'max_journals_displayed';
  static const String keyMaxKeywords = 'max_keywords_displayed';

  static const int defaultMaxJournals = 10;
  static const int defaultMaxKeywords = 20;

  bool _initialized = false;

  FirebaseRemoteConfig? get _rc =>
      firebaseReady ? FirebaseRemoteConfig.instance : null;

  Future<void> init() async {
    if (!firebaseReady || _initialized) return;
    try {
      final rc = _rc!;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await rc.setDefaults(const {
        keyMaxJournals: defaultMaxJournals,
        keyMaxKeywords: defaultMaxKeywords,
      });
      await rc.fetchAndActivate();
      _initialized = true;
      debugPrint('✅ Remote Config loaded: '
          'journals=$maxJournals, keywords=$maxKeywords');
    } catch (e) {
      debugPrint('Remote Config init error: $e');
    }
  }

  /// Force a refresh (used by the Profile "Refresh" button).
  Future<void> refresh() async {
    if (!firebaseReady) return;
    try {
      await _rc?.fetchAndActivate();
    } catch (e) {
      debugPrint('Remote Config refresh error: $e');
    }
  }

  int get maxJournals {
    final v = _rc?.getInt(keyMaxJournals) ?? 0;
    return v > 0 ? v : defaultMaxJournals;
  }

  int get maxKeywords {
    final v = _rc?.getInt(keyMaxKeywords) ?? 0;
    return v > 0 ? v : defaultMaxKeywords;
  }
}
