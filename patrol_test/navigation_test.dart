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
  /// Login → search topic → chuyển tab Journals → verify THỐNG KÊ journal
  /// (số journal / công bố / trích dẫn) VÀ danh sách journal hiển thị.
  patrolTest('TC4 - Journals Navigation', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabJournals)).tap();

    // Journals tab tự search lại theo topic đã set ở Home ⇒ chờ mạng.
    // Cả 2 key chỉ tồn tại khi danh sách có dữ liệu.
    await $(const Key(WidgetKeys.journalsStats)).waitUntilVisible(
      timeout: networkTimeout,
    );
    await $(const Key(WidgetKeys.journalListFirst)).waitUntilVisible(
      timeout: networkTimeout,
    );

    // Đề bài đòi cả "statistics" lẫn "list".
    expect($(const Key(WidgetKeys.journalsStats)).visible, true);
    expect($(const Key(WidgetKeys.journalListFirst)).visible, true);
  });

  /// Test Case 6 — Keywords Navigation.
  /// Login → search topic → chuyển tab Keywords → verify THỐNG KÊ keyword
  /// (card trending) VÀ danh sách keyword hiển thị.
  patrolTest('TC6 - Keywords Navigation', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabKeywords)).tap();

    await $(const Key(WidgetKeys.keywordsStats)).waitUntilVisible(
      timeout: networkTimeout,
    );
    await $(const Key(WidgetKeys.keywordListFirst)).waitUntilVisible(
      timeout: networkTimeout,
    );

    expect($(const Key(WidgetKeys.keywordsStats)).visible, true);
    expect($(const Key(WidgetKeys.keywordListFirst)).visible, true);
  });

  /// Test Case 8 — Profile Navigation.
  /// Login → chuyển tab Profile → verify THÔNG TIN USER hiển thị
  /// (card chứa tên + email + avatar).
  ///
  /// Không cần search trước: Profile không phụ thuộc dữ liệu dashboard
  /// (trừ nút Export PDF — xem TC9).
  patrolTest('TC8 - Profile Navigation', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.tabProfile)).tap();

    // Card thông tin user là thứ đề bài đòi verify.
    await $(const Key(WidgetKeys.profileUserCard)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.profileUserCard)).visible, true);

    // Card phải thực sự render tên + email, không rỗng. Scope trong card nên
    // không phụ thuộc text hiển thị (tên/email là dữ liệu user, không dịch).
    expect($(const Key(WidgetKeys.profileUserCard)).$(Text).exists, true);

    // Notification Center là widget đặc trưng còn lại của màn Profile.
    await $(const Key(WidgetKeys.notificationCenterCard)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.notificationCenterCard)).visible, true);
  });
}
