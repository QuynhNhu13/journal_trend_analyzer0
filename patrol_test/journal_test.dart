import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Chi tiết journal.
void main() {
  /// Test Case 5 — Journal Details.
  /// Login → search topic → tab Journals → tap journal đầu tiên →
  /// verify màn Journal Detail hiện ra (tên journal + thống kê).
  patrolTest('TC5 - Journal Details', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabJournals)).tap();

    // journals_stats (đầu list) = mốc chờ request, có retry cho OpenAlex.
    await waitForDataWithRetry($, $(const Key(WidgetKeys.journalsStats)));
    // journal_list_first nằm dưới stats + biểu đồ ⇒ ngoài viewport trên máy nhỏ.
    // Cuộn tới (đúng Scrollable của list) trước khi tap — tap không tự cuộn.
    await scrollToInList($, $(const Key(WidgetKeys.journalListFirst)),
        anchorKeyInList: WidgetKeys.journalsStats);
    await $(const Key(WidgetKeys.journalListFirst)).tap();

    // JournalDetailScreen: BrandedHeader mang key + tên journal.
    await $(const Key(WidgetKeys.journalDetailTitle)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.journalDetailTitle)).visible, true);

    // Thống kê / danh sách publication của journal được nạp từ mạng.
    await $(const Key(WidgetKeys.publicationListFirst)).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(const Key(WidgetKeys.publicationListFirst)).visible, true);
  });
}
