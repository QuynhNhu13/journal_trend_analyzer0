import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/firebase/firebase_bootstrap.dart';
import 'package:journal_trend_analyzer/main.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

/// Shared helpers for the Patrol E2E suite (patrol 4.7.1 / patrol_cli 4.5.1).
///
/// Điều kiện chạy:
///   • Điện thoại Android thật, đã đăng nhập sẵn tài khoản Google
///     (Settings → Accounts). Native account picker sẽ hiện tài khoản đó.
///   • Mạng ổn định — dữ liệu OpenAlex trả về chậm nên mọi bước chờ mạng dùng
///     [networkTimeout] = 30s.
///   • App giữ phiên đăng nhập giữa các lần chạy (không dùng clearPackageData),
///     nên hầu hết test sẽ đi thẳng vào Home qua [loginIfNeeded].
///
/// Quy ước tìm widget: LUÔN dùng ValueKey trong `lib/utils/widget_keys.dart`.
/// Không tìm theo text hiển thị — app song ngữ EN/VI, text đổi theo locale.

/// Timeout cho mọi bước chờ dữ liệu mạng (OpenAlex).
const Duration networkTimeout = Duration(seconds: 30);

/// Timeout cho các chuyển màn hình cục bộ (không gọi mạng).
const Duration uiTimeout = Duration(seconds: 10);

/// Splash hiện 2200ms rồi fade 450ms sang AuthGate.
const Duration _splashDuration = Duration(milliseconds: 3000);

/// Bơm cây widget production và chờ splash đi qua.
///
/// `main()` bootstrap Firebase trước `runApp`, nên test phải làm y hệt —
/// nếu không, `firebaseReady` = false và app rơi vào nhánh demo/no-Firebase.
Future<void> launchApp(PatrolIntegrationTester $) async {
  await bootstrapFirebase();
  await $.pumpWidget(const JournalTrendApp());
  // Không dùng pumpAndSettle ở đây: AuthGate hiển thị CircularProgressIndicator
  // (animation vô hạn) khi đang khởi tạo auth ⇒ pumpAndSettle sẽ timeout.
  await $.pump(_splashDuration);
}

/// Bơm frame cho tới khi MỘT trong [finders] xuất hiện, tối đa [timeout].
///
/// Dùng thay cho pumpAndSettle khi trên màn hình có animation vô hạn
/// (CircularProgressIndicator), và khi ta chưa biết sẽ ra Login hay Home.
/// Trả về true nếu tìm thấy; false nếu hết thời gian.
Future<bool> _pumpUntilAny(
  PatrolIntegrationTester $,
  List<PatrolFinder> finders, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    for (final finder in finders) {
      if (finder.exists) return true;
    }
    await $.pump(const Duration(milliseconds: 150));
  }
  return false;
}

/// Chờ AuthGate quyết định xong: hiện Login hoặc vào MainShell.
Future<void> _waitForAuthGate(PatrolIntegrationTester $) async {
  final resolved = await _pumpUntilAny(
    $,
    [
      $(const Key(WidgetKeys.googleSigninButton)),
      $(const Key(WidgetKeys.tabHome)),
    ],
    timeout: networkTimeout,
  );
  if (!resolved) {
    fail(
      'AuthGate không hiện Login lẫn Home sau ${networkTimeout.inSeconds}s. '
      'Kiểm tra kết nối mạng và cấu hình Firebase trên máy.',
    );
  }
}

/// Thực hiện đầy đủ luồng Google Sign-In qua native account picker.
///
/// Giả định đang đứng ở Login screen. Sau khi tap nút Google, hệ điều hành
/// bật popup chọn tài khoản — đây là view NATIVE nên phải dùng platform
/// automator, Flutter finder không thấy được.
Future<void> signInWithGoogle(PatrolIntegrationTester $) async {
  await $(const Key(WidgetKeys.googleSigninButton)).waitUntilVisible(
    timeout: uiTimeout,
  );
  await $(const Key(WidgetKeys.googleSigninButton)).tap();

  // Chọn tài khoản đã đăng nhập sẵn trên máy trong popup native.
  // `$.platform` là API hiện hành của patrol 4.7.x — `$.native` đã deprecated.
  await $.platform.tap(
    Selector(textContains: '@gmail.com'),
    timeout: networkTimeout,
  );

  // Firebase đổi credential → AuthGate rebuild sang MainShell.
  await $(const Key(WidgetKeys.tabHome)).waitUntilVisible(
    timeout: networkTimeout,
  );
}

/// Khởi động app và đảm bảo đang ở trong MainShell (Home).
///
/// • Nếu màn hình hiện `google_signin_button` ⇒ chạy luồng sign-in đầy đủ.
/// • Nếu đã đăng nhập sẵn (thấy widget của Home) ⇒ bỏ qua.
Future<void> loginIfNeeded(PatrolIntegrationTester $) async {
  await launchApp($);
  await _waitForAuthGate($);

  if ($(const Key(WidgetKeys.tabHome)).exists) {
    return; // Phiên đăng nhập còn hiệu lực — vào thẳng Home.
  }
  await signInWithGoogle($);
}

/// Đăng xuất từ Profile để đưa app về Login screen.
///
/// Dùng cho TC1 (cần trạng thái CHƯA đăng nhập) và là thân của TC11.
/// Giả định đang ở trong MainShell.
Future<void> logout(PatrolIntegrationTester $) async {
  await $(const Key(WidgetKeys.tabProfile)).tap();
  // Sign Out nằm cuối ListView của Profile ⇒ phải cuộn tới.
  await $(const Key(WidgetKeys.signoutButton)).scrollTo();
  await $(const Key(WidgetKeys.signoutButton)).tap();
  await $(const Key(WidgetKeys.googleSigninButton)).waitUntilVisible(
    timeout: networkTimeout,
  );
}

/// Nhập [topic] vào ô search ở Home, submit, và chờ dashboard có dữ liệu.
///
/// Submit bằng cách tap `search_submit_home` thay vì phím Search của bàn phím —
/// không phụ thuộc soft-keyboard nên ổn định hơn trên máy thật.
/// `dashboard_total_papers` chỉ render khi search thành công ⇒ dùng làm mốc chờ.
Future<void> searchTopic(PatrolIntegrationTester $, String topic) async {
  await $(const Key(WidgetKeys.tabHome)).tap();
  await $(const Key(WidgetKeys.searchFieldHome)).enterText(topic);
  await $(const Key(WidgetKeys.searchSubmitHome)).tap();
  await $(const Key(WidgetKeys.dashboardTotalPapers)).waitUntilVisible(
    timeout: networkTimeout,
  );
}
