import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Test Case 1 – Google Sign-In (lab §8) and Test Case 11 – Logout.
void main() {
  patrolTest('TC1: màn Login hiển thị và nút Google Sign-In khả dụng',
      ($) async {
    await launchApp($);

    // The Login screen must be shown before authentication.
    expect($('Đăng nhập với Google').exists, true);

    // Tapping starts the Google Sign-In flow. On a device with a Google
    // account configured, the native account picker appears; select an
    // account with `$.native.tap(...)`. Here we verify the button is tappable.
    await $.tap($('Đăng nhập với Google'));
    await $.pump(const Duration(seconds: 2));

    // After a successful sign-in the Home tab is shown:
    // expect($('Home').visible, true);
  });

  patrolTest('TC11: đăng xuất quay lại màn Login', ($) async {
    await enterHome($);

    // Go to Profile tab and sign out.
    await $.tap($('Profile'));
    await $.pumpAndSettle();
    await $.scrollUntilVisible(finder: $('Đăng xuất'));
    await $.tap($('Đăng xuất'));
    await $.pumpAndSettle();

    // Back on the Login screen.
    expect($('Đăng nhập với Google').exists, true);
  });
}
