import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Google Sign-In và Logout.
///
/// ĐIỀU KIỆN TRẠNG THÁI (khác các file test còn lại):
///   • TC1 cần trạng thái CHƯA đăng nhập. App giữ phiên giữa các lần chạy nên
///     test tự logout trước để tạo lại trạng thái đó.
///   • TC11 cần trạng thái ĐÃ đăng nhập, nên tự [loginIfNeeded] trước.
///   • Chạy tuần tự trong cùng file: TC1 kết thúc ở Home (đã đăng nhập), là
///     đúng tiền đề cho TC11. TC11 kết thúc ở Login, và TC1 tự xử lý được cả
///     hai trạng thái ⇒ chạy lại file nhiều lần vẫn đúng.
void main() {
  /// Test Case 1 — Google Sign-In.
  /// Từ trạng thái CHƯA đăng nhập: nếu app đang đăng nhập sẵn thì logout trước
  /// → verify về Login screen → thực hiện sign-in đầy đủ qua native popup →
  /// verify vào Home thành công.
  patrolTest('TC1 - Google Sign-In', ($) async {
    // Đưa app về trạng thái chưa đăng nhập nếu phiên cũ còn hiệu lực.
    // (`loginIfNeeded` đã bao gồm bước khởi động app.)
    await loginIfNeeded($);
    await logout($);

    // Verify đang ở Login screen.
    await $(const Key(WidgetKeys.googleSigninButton)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.googleSigninButton)).visible, true);
    expect($(const Key(WidgetKeys.tabHome)).exists, false);

    // Luồng sign-in đầy đủ: tap nút Google → chọn tài khoản ở popup native.
    await signInWithGoogle($);

    // Verify vào Home thành công.
    expect($(const Key(WidgetKeys.tabHome)).visible, true);
    expect($(const Key(WidgetKeys.searchFieldHome)).exists, true);
  });

  /// Test Case 11 — Logout.
  /// Từ trạng thái đã đăng nhập → tab Profile → tap `signout_button` →
  /// verify điều hướng về Login screen (`google_signin_button` hiện).
  patrolTest('TC11 - Logout', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.tabProfile)).tap();

    // Sign Out nằm cuối ListView của Profile ⇒ phải cuộn tới.
    await $(const Key(WidgetKeys.signoutButton)).scrollTo();
    await $(const Key(WidgetKeys.signoutButton)).tap();

    // AuthGate rebuild sang LoginScreen.
    await $(const Key(WidgetKeys.googleSigninButton)).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(const Key(WidgetKeys.googleSigninButton)).visible, true);
    expect($(const Key(WidgetKeys.tabHome)).exists, false);
  });
}
