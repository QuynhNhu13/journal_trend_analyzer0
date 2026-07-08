import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// Central place for all Firebase Analytics events required by the lab:
/// login, search_topic, view_publication, view_journal, view_keyword,
/// export_pdf, logout.
///
/// Every call is null-safe against Firebase not being configured yet.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? get _analytics =>
      firebaseReady ? FirebaseAnalytics.instance : null;

  /// A navigation observer you can plug into MaterialApp to auto-track screens.
  FirebaseAnalyticsObserver? get observer =>
      firebaseReady ? FirebaseAnalyticsObserver(analytics: _analytics!) : null;

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics?.logEvent(name: name, parameters: params);
      debugPrint('📊 analytics: $name ${params ?? ''}');
    } catch (e) {
      debugPrint('analytics error ($name): $e');
    }
  }

  Future<void> setUser(String? uid) async {
    try {
      await _analytics?.setUserId(id: uid);
    } catch (_) {}
  }

  // ── Required events ──────────────────────────────────────────────────
  Future<void> logLogin({String method = 'google'}) async {
    try {
      await _analytics?.logLogin(loginMethod: method);
      debugPrint('📊 analytics: login ($method)');
    } catch (_) {}
  }

  Future<void> logLogout() => _log('logout');

  Future<void> logSearchTopic(String keyword) =>
      _log('search_topic', {'keyword': keyword});

  Future<void> logViewPublication({
    required String title,
    int? year,
  }) =>
      _log('view_publication', {
        'publication_title': title,
        if (year != null) 'publication_year': year,
      });

  Future<void> logViewJournal(String journalName) =>
      _log('view_journal', {'journal_name': journalName});

  Future<void> logViewKeyword(String keyword) =>
      _log('view_keyword', {'keyword': keyword});

  Future<void> logExportPdf(String topic) =>
      _log('export_pdf', {'topic': topic});
}
