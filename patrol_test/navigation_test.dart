import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Điều hướng giữa các tab của MainShell.
///
/// Mọi test tự [loginIfNeeded] nên chạy độc lập, không phụ thuộc thứ tự.
void main() {
  /// Test Case 4 — Journals Navigation.
  /// Login → search topic → tap tab Journals → verify danh sách/thống kê
  /// journal hiện ra.
  patrolTest('TC4 - Journals Navigation', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabJournals)).tap();

    // Journals tab tự search lại theo topic đã set ở Home ⇒ chờ mạng.
    // `journal_list_first` chỉ tồn tại khi danh sách có dữ liệu.
    await $(const Key(WidgetKeys.journalListFirst)).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(const Key(WidgetKeys.journalListFirst)).visible, true);
  });

  /// Test Case 6 — Keywords Navigation.
  /// Login → search topic → tap tab Keywords → verify danh sách keyword hiện ra.
  patrolTest('TC6 - Keywords Navigation', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabKeywords)).tap();

    await $(const Key(WidgetKeys.keywordListFirst)).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(const Key(WidgetKeys.keywordListFirst)).visible, true);
  });

  /// Test Case 8 — Profile Navigation.
  /// Login → tap tab Profile → verify thông tin user hiện ra (dùng card
  /// Notification Center làm widget đặc trưng của Profile).
  ///
  /// Không cần search trước: Profile không phụ thuộc dữ liệu dashboard
  /// (trừ nút Export PDF — xem TC9).
  patrolTest('TC8 - Profile Navigation', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.tabProfile)).tap();

    await $(const Key(WidgetKeys.notificationCenterCard)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.notificationCenterCard)).visible, true);
  });
}
