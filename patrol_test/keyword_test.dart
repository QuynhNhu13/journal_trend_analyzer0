import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/screens/keyword_detail_screen.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Chi tiết keyword.
void main() {
  /// Test Case 7 — Keyword Details.
  /// Login → search topic → tab Keywords → tap keyword đầu tiên →
  /// verify màn Keyword Detail hiện ra (trend + danh sách liên quan).
  patrolTest('TC7 - Keyword Details', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabKeywords)).tap();

    // keywords_stats (card trending, đầu list) = mốc chờ dữ liệu, có retry.
    await waitForDataWithRetry($, $(const Key(WidgetKeys.keywordsStats)));
    // keyword_list_first (bar đầu) nằm dưới card trending ⇒ cuộn tới (đúng
    // Scrollable của list) trước khi tap.
    await scrollToInList($, $(const Key(WidgetKeys.keywordListFirst)),
        anchorKeyInList: WidgetKeys.keywordsStats);
    await $(const Key(WidgetKeys.keywordListFirst)).tap();

    // KeywordDetailScreen: BrandedHeader mang key + tên keyword.
    await $(const Key(WidgetKeys.keywordDetailTitle)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.keywordDetailTitle)).visible, true);

    // Trend + danh sách liên quan: màn này tự nạp mạng, chỉ dựng ListView nội
    // dung SAU khi xong (trước đó là StateView.loading / có thể là error). Nên
    // ListView xuất hiện là bằng chứng dữ liệu đã về ⇒ bọc retry. Giới hạn finder
    // trong KeywordDetailScreen — 4 tab IndexedStack vẫn trong tree nên
    // $(ListView) trần sẽ mơ hồ.
    await waitForDataWithRetry($, $(KeywordDetailScreen).$(ListView));
    expect($(KeywordDetailScreen).$(ListView).visible, true);
  });
}
