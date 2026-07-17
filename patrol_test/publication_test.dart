import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/screens/detail_screen.dart';
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

    // KPI "Total Papers" chỉ render sau khi search thành công ⇒ mốc chờ, có retry.
    await waitForDataWithRetry($, $(const Key(WidgetKeys.dashboardTotalPapers)));
    expect($(const Key(WidgetKeys.dashboardTotalPapers)).visible, true);

    // Kết quả: card "Most Influential Paper" kèm nút Details — nằm dưới KPI +
    // chart ⇒ cuộn tới trong đúng Scrollable của dashboard (neo theo KPI ở đầu).
    await scrollToInList($, $(const Key(WidgetKeys.dashboardPaperDetails)),
        anchorKeyInList: WidgetKeys.dashboardTotalPapers);
    expect($(const Key(WidgetKeys.dashboardPaperDetails)).visible, true);
  });

  /// Test Case 3 — Publication Details.
  /// Từ kết quả search, tap publication đầu tiên → verify màn Detail hiện
  /// đúng (tiêu đề màn hình + các trường thông tin của bài báo).
  patrolTest('TC3 - Publication Details', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    // Publication đầu tiên của kết quả search = card "Most Influential Paper".
    // (searchTopic đã bọc retry cho phần chờ dữ liệu Home.)
    await scrollToInList($, $(const Key(WidgetKeys.dashboardPaperDetails)),
        anchorKeyInList: WidgetKeys.dashboardTotalPapers);
    await $(const Key(WidgetKeys.dashboardPaperDetails)).tap();

    // DetailScreen được push bằng MaterialPageRoute.
    await $(const Key(WidgetKeys.publicationDetailTitle)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.publicationDetailTitle)).visible, true);

    // Màn detail phải render nội dung bài báo, không chỉ mỗi AppBar. Scope
    // trong DetailScreen vì $(Text) trần khớp mọi tab đang mounted.
    expect($(DetailScreen).$(Text).exists, true);
  });
}
