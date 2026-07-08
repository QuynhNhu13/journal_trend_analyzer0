import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Test Case 2 – Topic Search and Test Case 3 – Publication Details (lab §8).
void main() {
  patrolTest('TC2: tìm chủ đề hiển thị kết quả', ($) async {
    await enterHome($);

    await searchTopic($, 'machine learning');

    // The dashboard shows the "Papers Retrieved:" indicator after a search.
    expect($('Papers Retrieved:').exists, true);
  });

  patrolTest('TC3: mở chi tiết một công bố', ($) async {
    await enterHome($);
    await searchTopic($, 'machine learning');

    // Open the most influential paper's detail from the dashboard card.
    final details = $('Details');
    if (details.exists) {
      await $.tap(details);
      await $.pumpAndSettle();

      // The detail screen shows citation/year metadata.
      expect($('DOI').exists || $('Abstract').exists, isTrue);
    }
  });
}
