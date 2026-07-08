import 'package:flutter/material.dart';
import 'package:journal_trend_analyzer/main.dart';
import 'package:patrol/patrol.dart';

/// Shared helpers for the Patrol E2E suite.
///
/// NOTE: These tests require a configured device/emulator and completed
/// Firebase setup (FIREBASE_SETUP.md). Scenarios other than the real Google
/// Sign-In use the built-in "demo mode" entry so the suite is runnable even
/// before a Google account is wired up on the test device.

/// Pumps the full production app tree and waits for the splash to pass.
Future<void> launchApp(PatrolIntegrationTester $) async {
  await $.pumpWidget(const JournalTrendApp());
  // Splash shows for ~2.2s before navigating to the AuthGate.
  await $.pump(const Duration(seconds: 3));
  await $.pumpAndSettle();
}

/// Ensures we are inside the main app (Home tab). If the Login screen is
/// showing, enter through demo mode so downstream tests can run without a
/// real Google account.
Future<void> enterHome(PatrolIntegrationTester $) async {
  await launchApp($);
  final demo = $('Xem thử ở chế độ demo →');
  if (demo.exists) {
    await $.tap(demo);
    await $.pumpAndSettle();
  }
}

/// Types [topic] into the first visible search field and submits it.
Future<void> searchTopic(PatrolIntegrationTester $, String topic) async {
  final field = $(TextField).first;
  await $.enterText(field, topic);
  await $.tester.testTextInput.receiveAction(TextInputAction.search);
  await $.pumpAndSettle(timeout: const Duration(seconds: 20));
}
