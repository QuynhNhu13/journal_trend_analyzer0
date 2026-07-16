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

    // Chờ frequency bars có dữ liệu rồi mới tap bar đầu tiên.
    await $(const Key(WidgetKeys.keywordListFirst)).waitUntilVisible(
      timeout: networkTimeout,
    );
    await $(const Key(WidgetKeys.keywordListFirst)).tap();

    // KeywordDetailScreen: BrandedHeader mang key + tên keyword.
    await $(const Key(WidgetKeys.keywordDetailTitle)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.keywordDetailTitle)).visible, true);

    // Trend + danh sách liên quan: màn này chỉ dựng ListView nội dung SAU khi
    // nạp xong (trước đó là StateView.loading), nên ListView xuất hiện là bằng
    // chứng dữ liệu đã về. Phải giới hạn finder trong KeywordDetailScreen —
    // 4 tab của IndexedStack vẫn còn trong tree nên $(ListView) trần sẽ mơ hồ.
    await $(KeywordDetailScreen).$(ListView).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(KeywordDetailScreen).$(ListView).visible, true);
  });
}
