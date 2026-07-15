import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Test Case 8 – Profile Navigation (lab §8).
void main() {
  patrolTest('TC8: mở tab Profile và hiển thị thông tin người dùng', ($) async {
    await enterHome($);

    await $.tap($('Profile'));
    await $.pumpAndSettle();

    // Profile shows the Firebase service sections.
    expect($('Notification Center').exists, true);
    expect($('Remote Config').exists, true);
    expect($('Crashlytics Demo').exists, true);
  });
}
