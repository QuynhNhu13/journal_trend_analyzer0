import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analyzer/screens/detail_screen.dart';
import 'package:journal_trend_analyzer/screens/keyword_detail_screen.dart';
import 'package:journal_trend_analyzer/utils/widget_keys.dart';
import 'package:patrol/patrol.dart';

import 'test_helpers.dart';

/// Bộ E2E đầy đủ TC1 → TC11, xếp theo THỨ TỰ DEMO.
///
/// Vì sao gộp 1 file: khi chạy cả thư mục, patrol nạp test theo thứ tự file
/// (alphabet) nên các TC nằm rải ở nhiều file sẽ chạy lộn xộn. Gộp vào một file
/// và khai báo theo thứ tự ⇒ chạy đúng TC1→TC11.
///
/// Dòng trạng thái phiên (app giữ login giữa các lần chạy):
///   • TC1  đăng nhập (kết thúc ở Home).
///   • TC2–TC10 đã đăng nhập sẵn ⇒ [loginIfNeeded] vào thẳng Home (nhanh).
///   • TC11 đăng xuất (kết thúc ở Login) ⇒ đóng vòng demo gọn gàng.
///
/// Chống OpenAlex chập chờn: mọi bước chờ DỮ LIỆU MẠNG đi qua
/// [waitForDataWithRetry] / [searchTopic] (tự bấm "Try again" khi gặp error
/// state). Mọi item DANH SÁCH khuất dùng [scrollToInList] để cuộn đúng Scrollable.
void main() {
  // ── TC1 — Google Sign-In ──
  // Từ trạng thái CHƯA đăng nhập: nếu còn phiên thì logout trước → verify Login
  // → sign-in đầy đủ qua native popup → verify vào Home.
  patrolTest('TC1 - Google Sign-In', ($) async {
    await loginIfNeeded($);
    await logout($);

    await $(const Key(WidgetKeys.googleSigninButton)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.googleSigninButton)).visible, true);
    expect($(const Key(WidgetKeys.tabHome)).exists, false);

    await signInWithGoogle($);

    expect($(const Key(WidgetKeys.tabHome)).visible, true);
    expect($(const Key(WidgetKeys.searchFieldHome)).exists, true);
  });

  // ── TC2 — Topic Search ──
  // Search "machine learning" → verify KPI Total Papers + card kết quả.
  patrolTest('TC2 - Topic Search', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.searchFieldHome)).enterText('machine learning');
    await $(const Key(WidgetKeys.searchSubmitHome)).tap();

    // dashboard_total_papers chỉ render khi search thành công ⇒ mốc chờ, có retry.
    await waitForDataWithRetry($, $(const Key(WidgetKeys.dashboardTotalPapers)));
    expect($(const Key(WidgetKeys.dashboardTotalPapers)).visible, true);

    // Card "Most Influential Paper" kèm nút Details nằm dưới KPI + chart ⇒ cuộn
    // tới trong đúng Scrollable của dashboard (neo theo KPI ở đầu).
    await scrollToInList($, $(const Key(WidgetKeys.dashboardPaperDetails)),
        anchorKeyInList: WidgetKeys.dashboardTotalPapers);
    expect($(const Key(WidgetKeys.dashboardPaperDetails)).visible, true);
  });

  // ── TC3 — Publication Details ──
  // Từ kết quả search, tap publication đầu tiên → verify màn Detail.
  patrolTest('TC3 - Publication Details', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await scrollToInList($, $(const Key(WidgetKeys.dashboardPaperDetails)),
        anchorKeyInList: WidgetKeys.dashboardTotalPapers);
    await $(const Key(WidgetKeys.dashboardPaperDetails)).tap();

    await $(const Key(WidgetKeys.publicationDetailTitle)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.publicationDetailTitle)).visible, true);

    // Màn detail phải render nội dung bài báo, không chỉ mỗi AppBar.
    expect($(DetailScreen).$(Text).exists, true);
  });

  // ── TC4 — Journals Navigation ──
  // Tab Journals → verify thống kê journal VÀ danh sách journal hiển thị.
  patrolTest('TC4 - Journals Navigation', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabJournals)).tap();

    // stats và danh sách dùng chung nguồn vm.journals ⇒ chờ stats (có retry) là
    // đủ; danh sách đã dựng trong tree.
    await waitForDataWithRetry($, $(const Key(WidgetKeys.journalsStats)));
    expect($(const Key(WidgetKeys.journalsStats)).visible, true);

    await scrollToInList($, $(const Key(WidgetKeys.journalListFirst)),
        anchorKeyInList: WidgetKeys.journalsStats);
    expect($(const Key(WidgetKeys.journalListFirst)).visible, true);
  });

  // ── TC5 — Journal Details ──
  // Tap journal đầu tiên → verify màn Journal Detail (tên + thống kê + list pub).
  patrolTest('TC5 - Journal Details', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabJournals)).tap();

    await waitForDataWithRetry($, $(const Key(WidgetKeys.journalsStats)));
    await scrollToInList($, $(const Key(WidgetKeys.journalListFirst)),
        anchorKeyInList: WidgetKeys.journalsStats);
    await $(const Key(WidgetKeys.journalListFirst)).tap();

    await $(const Key(WidgetKeys.journalDetailTitle)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.journalDetailTitle)).visible, true);

    // Danh sách publication của journal nằm sẵn trong model (không gọi mạng).
    await $(const Key(WidgetKeys.publicationListFirst)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.publicationListFirst)).visible, true);
  });

  // ── TC6 — Keywords Navigation ──
  // Tab Keywords → verify thống kê keyword VÀ danh sách keyword hiển thị.
  patrolTest('TC6 - Keywords Navigation', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabKeywords)).tap();

    await waitForDataWithRetry($, $(const Key(WidgetKeys.keywordsStats)));
    expect($(const Key(WidgetKeys.keywordsStats)).visible, true);

    await scrollToInList($, $(const Key(WidgetKeys.keywordListFirst)),
        anchorKeyInList: WidgetKeys.keywordsStats);
    expect($(const Key(WidgetKeys.keywordListFirst)).visible, true);
  });

  // ── TC7 — Keyword Details ──
  // Tap keyword đầu tiên → verify màn Keyword Detail (title + nội dung ListView).
  patrolTest('TC7 - Keyword Details', ($) async {
    await loginIfNeeded($);
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabKeywords)).tap();

    await waitForDataWithRetry($, $(const Key(WidgetKeys.keywordsStats)));
    await scrollToInList($, $(const Key(WidgetKeys.keywordListFirst)),
        anchorKeyInList: WidgetKeys.keywordsStats);
    await $(const Key(WidgetKeys.keywordListFirst)).tap();

    await $(const Key(WidgetKeys.keywordDetailTitle)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.keywordDetailTitle)).visible, true);

    // KeywordDetailScreen tự nạp mạng, chỉ dựng ListView SAU khi xong ⇒ có retry.
    // Giới hạn finder trong màn này (IndexedStack còn các tab khác trong tree).
    await waitForDataWithRetry($, $(KeywordDetailScreen).$(ListView));
    expect($(KeywordDetailScreen).$(ListView).visible, true);
  });

  // ── TC8 — Profile Navigation ──
  // Tab Profile → verify card thông tin user + Notification Center.
  patrolTest('TC8 - Profile Navigation', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.tabProfile)).tap();

    await $(const Key(WidgetKeys.profileUserCard)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.profileUserCard)).visible, true);
    expect($(const Key(WidgetKeys.profileUserCard)).$(Text).exists, true);

    await $(const Key(WidgetKeys.notificationCenterCard)).waitUntilVisible(
      timeout: uiTimeout,
    );
    expect($(const Key(WidgetKeys.notificationCenterCard)).visible, true);
  });

  // ── TC9 — PDF Export ──
  // Tab Profile → Export PDF → upload Firebase Storage → verify URL hiển thị.
  patrolTest('TC9 - PDF Export', ($) async {
    await loginIfNeeded($);
    // Export chỉ bật khi đã có dữ liệu dashboard ⇒ search trước (có retry).
    await searchTopic($, 'machine learning');

    await $(const Key(WidgetKeys.tabProfile)).tap();

    await $(const Key(WidgetKeys.exportPdfButton)).scrollTo();
    await $(const Key(WidgetKeys.exportPdfButton)).waitUntilVisible(
      timeout: uiTimeout,
    );
    await $(const Key(WidgetKeys.exportPdfButton)).tap();

    // Dựng PDF + upload Storage lâu hơn request mạng thường ⇒ uploadTimeout (60s).
    // URL hiện trong một SelectableText duy nhất của app (card Export).
    await $(SelectableText).waitUntilVisible(timeout: uploadTimeout);
    expect($(SelectableText).visible, true);
  });

  // ── TC10 — Remote Config ──
  // Tab Profile → verify 2 dòng giá trị Remote Config → refresh → vẫn hiển thị.
  patrolTest('TC10 - Remote Config', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.tabProfile)).tap();

    // Cuộn tới dòng DƯỚI CÙNG (keywords). scrollTo dừng NGAY khi target vừa
    // hit-testable (vừa ló ra ở đáy viewport), KHÔNG canh giữa. Nên nếu cuộn tới
    // journals trước, nó dừng lúc journals vừa ló ra ⇒ keywords vẫn khuất dưới
    // ⇒ assert keywords fail. Cuộn tới dòng thấp nhất kéo cả card Remote Config
    // (nhỏ) vào tầm nhìn: 2 dòng giá trị + nút refresh cùng hiển thị.
    await $(const Key(WidgetKeys.remoteConfigKeywordsValue)).scrollTo();
    expect($(const Key(WidgetKeys.remoteConfigJournalsValue)).visible, true);
    expect($(const Key(WidgetKeys.remoteConfigKeywordsValue)).visible, true);

    // Nút refresh nằm ngay trên 2 dòng nên đang hiển thị ⇒ tap trực tiếp
    // (scrollTo lên trên sẽ không tới được vì scrollTo chỉ cuộn xuôi xuống).
    await $(const Key(WidgetKeys.remoteConfigRefresh)).tap();

    // Sau refresh: không crash, 2 dòng giá trị vẫn còn hiển thị.
    await $(const Key(WidgetKeys.remoteConfigKeywordsValue)).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(const Key(WidgetKeys.remoteConfigJournalsValue)).visible, true);
    expect($(const Key(WidgetKeys.remoteConfigKeywordsValue)).visible, true);
  });

  // ── TC11 — Logout ──
  // Tab Profile → Sign Out → verify về Login screen. Đóng vòng demo.
  patrolTest('TC11 - Logout', ($) async {
    await loginIfNeeded($);

    await $(const Key(WidgetKeys.tabProfile)).tap();

    await $(const Key(WidgetKeys.signoutButton)).scrollTo();
    await $(const Key(WidgetKeys.signoutButton)).tap();

    await $(const Key(WidgetKeys.googleSigninButton)).waitUntilVisible(
      timeout: networkTimeout,
    );
    expect($(const Key(WidgetKeys.googleSigninButton)).visible, true);
    expect($(const Key(WidgetKeys.tabHome)).exists, false);
  });
}
