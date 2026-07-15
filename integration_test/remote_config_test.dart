import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Test Case 10 – Remote Config values are retrieved and displayed (lab §8).
void main() {
  patrolTest('TC10: hiển thị giá trị Remote Config', ($) async {
    await enterHome($);

    await $.tap($('Profile'));
    await $.pumpAndSettle();

    await $.scrollUntilVisible(finder: $('max_journals_displayed'));

    // Both required config keys are shown in the Remote Config section.
    expect($('max_journals_displayed').exists, true);
    expect($('max_keywords_displayed').exists, true);
  });
}
