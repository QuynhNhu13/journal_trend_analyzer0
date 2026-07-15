import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Test Case 4 – Journals Navigation and Test Case 5 – Journal Details (lab §8).
void main() {
  patrolTest('TC4: mở tab Journals và hiển thị danh sách', ($) async {
    await enterHome($);

    // Seed a topic on Home so Journals has data.
    await searchTopic($, 'deep learning');

    await $.tap($('Journals'));
    await $.pumpAndSettle(timeout: const Duration(seconds: 20));

    // Journal statistics section is shown.
    expect($('Xếp hạng tạp chí').exists || $('Đóng góp theo tạp chí').exists,
        isTrue);
  });

  patrolTest('TC5: mở chi tiết một tạp chí', ($) async {
    await enterHome($);
    await searchTopic($, 'deep learning');

    await $.tap($('Journals'));
    await $.pumpAndSettle(timeout: const Duration(seconds: 20));

    // Tap the first journal in the ranking list.
    await $.tap($('Chi tiết tạp chí').exists
        ? $('Chi tiết tạp chí')
        : $(ListTile).first);
    await $.pumpAndSettle();

    // Journal detail shows related publications.
    expect($('Công bố liên quan').exists, true);
  });
}
