import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Test Case 6 – Keywords Navigation and Test Case 7 – Keyword Details (lab §8).
void main() {
  patrolTest('TC6: mở tab Keywords và hiển thị danh sách', ($) async {
    await enterHome($);
    await searchTopic($, 'blockchain');

    await $.tap($('Keywords'));
    await $.pumpAndSettle(timeout: const Duration(seconds: 20));

    // Keyword statistics section is shown.
    expect($('Tần suất từ khóa').exists || $('Từ khóa nổi bật').exists, isTrue);
  });

  patrolTest('TC7: mở chi tiết một từ khóa', ($) async {
    await enterHome($);
    await searchTopic($, 'blockchain');

    await $.tap($('Keywords'));
    await $.pumpAndSettle(timeout: const Duration(seconds: 20));

    // Tap the first trending keyword chip.
    await $.tap($(ActionChip).first);
    await $.pumpAndSettle(timeout: const Duration(seconds: 20));

    // Keyword detail shows the analysis sections.
    expect(
        $('Xu hướng công bố').exists ||
            $('Tác giả đóng góp hàng đầu').exists,
        isTrue);
  });
}
