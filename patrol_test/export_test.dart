import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Xuất báo cáo PDF và upload lên Firebase Storage.
void main() {
  /// Test Case 9 — PDF Export.
  /// Login → search topic → tab Profile → tap `export_pdf_button` →
  /// verify upload thành công (URL hiện ra).
  ///
  /// SKIP: Chờ Firebase Storage bucket được kích hoạt (Blaze plan).
  /// Test đã viết đầy đủ — bỏ `skip` khi Storage sẵn sàng là chạy được ngay.
  patrolTest(
    'TC9 - PDF Export',
    skip: true,
    ($) async {
      await loginIfNeeded($);

      // Bắt buộc search trước: nút Export chỉ render khi dashboardSummary
      // != null, tức là đã có dữ liệu để đưa vào báo cáo.
      await searchTopic($, 'machine learning');

      await $(const Key(WidgetKeys.tabProfile)).tap();

      await $(const Key(WidgetKeys.exportPdfButton)).scrollTo();
      await $(const Key(WidgetKeys.exportPdfButton)).waitUntilVisible(
        timeout: uiTimeout,
      );
      await $(const Key(WidgetKeys.exportPdfButton)).tap();

      // Dựng PDF rồi upload lên Storage ⇒ chờ theo timeout mạng.
      // Upload xong, ProfileViewModel.reportUrl != null và URL hiện ra trong
      // một SelectableText — widget này chỉ xuất hiện đúng 1 chỗ trong toàn app
      // (card Export của Profile) nên finder theo type là không mơ hồ, và không
      // phụ thuộc text hiển thị (app song ngữ EN/VI).
      await $(SelectableText).waitUntilVisible(timeout: networkTimeout);
      expect($(SelectableText).visible, true);
    },
  );
}
