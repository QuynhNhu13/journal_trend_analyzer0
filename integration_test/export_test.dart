import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Test Case 9 – PDF Export & upload to Firebase Storage (lab §8).
///
/// Requires completed Firebase setup (Storage enabled). Without it the upload
/// step surfaces an error instead of a download URL.
void main() {
  patrolTest('TC9: xuất PDF và tải lên Storage', ($) async {
    await enterHome($);

    // A dashboard summary is required before exporting.
    await searchTopic($, 'artificial intelligence');

    await $.tap($('Profile'));
    await $.pumpAndSettle();

    await $.scrollUntilVisible(finder: $('Xuất PDF & tải lên Storage'));
    await $.tap($('Xuất PDF & tải lên Storage'));

    // Wait for build + upload.
    await $.pumpAndSettle(timeout: const Duration(seconds: 40));

    // On success a download URL card appears.
    expect($('Đã tải lên Firebase Storage').exists, true);
  });
}
