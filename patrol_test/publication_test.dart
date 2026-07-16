import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Tìm kiếm topic và xem chi tiết publication.
void main() {
  /// Test Case 2 — Topic Search.
  /// Login → search "machine learning" → verify `dashboard_total_papers`
  /// và danh sách kết quả hiện ra.
  patrolTest('TC2 - Topic Search', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.searchFieldHome)).enterText('machine learning');
    await $(const Key(WidgetKeys.searchSubmitHome)).tap();

    // KPI "Total Papers" chỉ render sau khi search thành công.
    await $(const Key(WidgetKeys.dashboardTotalPapers)).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(const Key(WidgetKeys.dashboardTotalPapers)).visible, true);

    // Kết quả: card "Most Influential Paper" kèm nút Details.
    await $(const Key(WidgetKeys.dashboardPaperDetails)).scrollTo();
    expect($(const Key(WidgetKeys.dashboardPaperDetails)).visible, true);
  });

  /// Test Case 3 — Publication Details.
  /// Từ kết quả search, tap publication đầu tiên → verify màn Detail hiện
  /// đúng (tiêu đề màn hình + các trường thông tin của bài báo).
  patrolTest('TC3 - Publication Details', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    // Publication đầu tiên của kết quả search = card "Most Influential Paper".
    await $(const Key(WidgetKeys.dashboardPaperDetails)).scrollTo();
    await $(const Key(WidgetKeys.dashboardPaperDetails)).tap();

    // DetailScreen được push bằng MaterialPageRoute.
    await $(const Key(WidgetKeys.publicationDetailTitle)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.publicationDetailTitle)).visible, true);

    // Màn detail phải render nội dung bài báo, không chỉ mỗi AppBar.
    expect($(Text).exists, true);
  });
}
