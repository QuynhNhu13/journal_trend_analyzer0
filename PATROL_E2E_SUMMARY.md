# Patrol E2E Test Suite — Tóm tắt

Bộ test E2E cho app **journal_trend_analyzer**, đáp ứng 11 test case bắt buộc của đề bài.
Toàn bộ file test nằm trong thư mục [`patrol_test/`](patrol_test/).

---

## 1. Phiên bản & tương thích

| Thành phần | Phiên bản | Ghi chú |
|---|---|---|
| Patrol CLI | `patrol_cli v4.5.1` | Đã cài sẵn trên máy |
| Package `patrol` | `4.7.1` | Khai báo `^4.7.1` trong `pubspec.yaml` |
| `patrol_finders` | `3.6.0` | Transitive dependency |

**Kết luận: KHÔNG cần nâng cấp.** Package `patrol` đã ở dòng **4.x**, tương thích với Patrol CLI 4.5.1
(CLI 4.x ↔ package 4.x). Không có bản 3.x nào cần nâng lên.

Đã xác nhận trong source của CLI 4.5.1 (`pubspec_reader.dart`) rằng `test_directory` mặc định là
`patrol_test` → không cần cấu hình thêm trong `pubspec.yaml`.

### Lưu ý API quan trọng: `$.native` đã deprecated

Trong patrol 4.7.1, `$.native` (và `$.native2`) bị đánh dấu `@Deprecated`, thay bằng **`$.platform`**:

```dart
// patrol-4.7.1/lib/src/custom_finders/patrol_integration_tester.dart
@Deprecated('Use platformAutomator instead. This will be removed in a future release.')
NativeAutomator get native => nativeAutomator;
```

Vì yêu cầu `flutter analyze` phải sạch, suite dùng `$.platform.tap(...)` thay cho `$.native.tap(...)`.
Hành vi và class `Selector` giữ nguyên — chỉ khác tên getter, không sinh cảnh báo deprecation:

```dart
await $.platform.tap(
  Selector(textContains: '@gmail.com'),
  timeout: networkTimeout,
);
```

Tương tự, `nativeAutomatorConfig` cũng deprecated (thay bằng `platformAutomatorConfig`) nên suite
không truyền tham số này — dùng config mặc định.

---

## 2. Thay đổi trong `lib/` (chỉ thêm key, không đổi logic)

Tổng cộng **+7 dòng**, không ảnh hưởng hành vi app:

| File | Thay đổi |
|---|---|
| `lib/utils/widget_keys.dart` | Thêm hằng `dashboardPaperDetails = 'dashboard_paper_details'` |
| `lib/screens/dashboard_screen.dart` | Gắn key trên vào nút *Details* của card "Most Influential Paper" |

**Lý do:** TC3 yêu cầu tap publication đầu tiên **từ kết quả search ở Home**, nhưng nút Details của
card "Most Influential Paper" chưa có key nào. Key `publication_list_first` sẵn có **không dùng được**
vì nó chỉ được gắn ở `journal_detail_screen.dart` — tái dùng sẽ khiến 1 key tồn tại ở 2 nơi cùng
mounted (Home + Journal Detail), gây finder mơ hồ (ambiguous). Vì vậy dùng key mới, riêng biệt.

---

## 3. Bảng tóm tắt 11 test case

Thiết bị test: **`RF8N5140DBL`** (SM A315G, Android 12).

| TC | Mô tả | File | Lệnh chạy |
|---|---|---|---|
| TC1 | Google Sign-In — logout trước → verify về Login → sign-in đầy đủ qua popup native → verify vào Home | `patrol_test/auth_test.dart` | `patrol test -t patrol_test/auth_test.dart -d RF8N5140DBL` |
| TC2 | Topic Search — search "machine learning" → verify `dashboard_total_papers` + danh sách kết quả | `patrol_test/publication_test.dart` | `patrol test -t patrol_test/publication_test.dart -d RF8N5140DBL` |
| TC3 | Publication Details — tap publication đầu tiên → verify `publication_detail_title` | `patrol_test/publication_test.dart` | `patrol test -t patrol_test/publication_test.dart -d RF8N5140DBL` |
| TC4 | Journals Navigation — tab Journals → verify `journal_list_first` | `patrol_test/navigation_test.dart` | `patrol test -t patrol_test/navigation_test.dart -d RF8N5140DBL` |
| TC5 | Journal Details — tap journal đầu tiên → verify `journal_detail_title` + thống kê | `patrol_test/journal_test.dart` | `patrol test -t patrol_test/journal_test.dart -d RF8N5140DBL` |
| TC6 | Keywords Navigation — tab Keywords → verify `keyword_list_first` | `patrol_test/navigation_test.dart` | `patrol test -t patrol_test/navigation_test.dart -d RF8N5140DBL` |
| TC7 | Keyword Details — tap keyword đầu tiên → verify `keyword_detail_title` + trend | `patrol_test/keyword_test.dart` | `patrol test -t patrol_test/keyword_test.dart -d RF8N5140DBL` |
| TC8 | Profile Navigation — tab Profile → verify `notification_center_card` | `patrol_test/navigation_test.dart` | `patrol test -t patrol_test/navigation_test.dart -d RF8N5140DBL` |
| TC9 | PDF Export — export → verify URL upload (**SKIP**, xem §6) | `patrol_test/export_test.dart` | `patrol test -t patrol_test/export_test.dart -d RF8N5140DBL` |
| TC10 | Remote Config — verify 2 dòng giá trị → refresh → verify vẫn hiển thị | `patrol_test/remote_config_test.dart` | `patrol test -t patrol_test/remote_config_test.dart -d RF8N5140DBL` |
| TC11 | Logout — tab Profile → `signout_button` → verify về Login screen | `patrol_test/auth_test.dart` | `patrol test -t patrol_test/auth_test.dart -d RF8N5140DBL` |

**Chạy toàn bộ suite:**

```bash
patrol test -d RF8N5140DBL
```

---

## 4. Cấu trúc file

```
patrol_test/
├── test_helpers.dart        # loginIfNeeded, searchTopic, signInWithGoogle, logout, launchApp
├── auth_test.dart           # TC1, TC11
├── publication_test.dart    # TC2, TC3
├── navigation_test.dart     # TC4, TC6, TC8
├── journal_test.dart        # TC5
├── keyword_test.dart        # TC7
├── remote_config_test.dart  # TC10
└── export_test.dart         # TC9 (skip)
```

### Helper dùng chung — `test_helpers.dart`

| Hàm | Vai trò |
|---|---|
| `launchApp($)` | `bootstrapFirebase()` → `pumpWidget(JournalTrendApp())` → chờ splash (2200ms + fade 450ms) |
| `loginIfNeeded($)` | Khởi động app; thấy `google_signin_button` → sign-in; đã đăng nhập → bỏ qua |
| `signInWithGoogle($)` | Tap nút Google → `$.platform.tap(Selector(textContains: '@gmail.com'))` → chờ vào Home |
| `logout($)` | Tab Profile → cuộn tới `signout_button` → tap → chờ về Login |
| `searchTopic($, topic)` | Tab Home → nhập topic → tap `search_submit_home` → chờ `dashboard_total_papers` |

Hằng số timeout: `networkTimeout = 30s` (mọi bước chờ OpenAlex), `uiTimeout = 10s` (chuyển màn cục bộ).

---

## 5. Các quyết định kỹ thuật đáng chú ý

**Phải gọi `bootstrapFirebase()` trước `pumpWidget`.** `main()` bootstrap Firebase trước `runApp`;
nếu test bỏ qua thì cờ `firebaseReady = false` và app rơi vào nhánh no-Firebase (hiện nút demo mode
thay vì luồng Google Sign-In thật).

**Không dùng `pumpAndSettle` sau splash.** AuthGate hiển thị `CircularProgressIndicator` — animation
vô hạn khiến `pumpAndSettle` timeout. Thay vào đó `launchApp` dùng vòng pump có deadline, chờ đến khi
Login **hoặc** Home xuất hiện. Không có `sleep`/delay hardcode ở bất kỳ đâu trong suite.

**Submit search bằng nút, không bằng bàn phím.** Tap `search_submit_home` ổn định hơn trên máy thật vì
không phụ thuộc soft-keyboard (dù `TopicSearchBar` hỗ trợ cả hai đường).

**TC7 lệch khỏi mẫu chung.** `KeywordDetailScreen` **không** có key `publication_list_first` (key đó chỉ
tồn tại ở Journal Detail). Bằng chứng "dữ liệu đã về" là `ListView` nội dung — màn này chỉ dựng ListView
sau khi nạp xong, trước đó là `StateView.loading`. Finder phải scope trong `$(KeywordDetailScreen)` vì
cả 4 tab đều mounted trong `IndexedStack` nên `$(ListView)` trần sẽ mơ hồ.

**TC9 verify URL qua `$(SelectableText)`.** An toàn vì widget này xuất hiện đúng 1 chỗ trong toàn app
(card Export của Profile) — đã grep xác nhận.

**TC1/TC11 có ràng buộc trạng thái, đã ghi chú trong file.** TC1 tự logout để dựng lại trạng thái chưa
đăng nhập; TC1 kết thúc ở Home (đúng tiền đề cho TC11); TC11 kết thúc ở Login và TC1 xử lý được cả hai
trạng thái ⇒ chạy lại nhiều lần vẫn đúng. Các test còn lại đều tự `loginIfNeeded`, độc lập thứ tự chạy.

**Không tìm widget theo text.** Toàn bộ finder dùng `ValueKey` từ `lib/utils/widget_keys.dart`, vì app
song ngữ EN/VI (mọi string đi qua `context.s.<key>`) nên text finder sẽ vỡ khi đổi locale. Hai chỗ dùng
finder theo widget type (`$(ListView)` ở TC7, `$(SelectableText)` ở TC9) cũng không phụ thuộc text.

---

## 6. TC9 — PDF Export bị SKIP

```dart
patrolTest(
  'TC9 - PDF Export',
  skip: true,   // Chờ Firebase Storage bucket được kích hoạt (Blaze plan)
  ($) async { ... },
);
```

Test đã viết **đầy đủ** kịch bản (login → search → tab Profile → tap `export_pdf_button` → verify URL).
Khi Firebase Storage sẵn sàng, chỉ cần **xoá dòng `skip: true`** là chạy được ngay.

Lưu ý: nút `export_pdf_button` chỉ render khi `dashboardSummary != null` — bắt buộc phải search trước,
nếu không sẽ chỉ thấy dòng hint và nút không tồn tại trong tree.

---

## 7. Điều kiện tiên quyết khi chạy

- **Điện thoại cắm cáp USB**, đã bật USB debugging; xác nhận bằng `flutter devices` thấy `RF8N5140DBL`.
- **Đã đăng nhập sẵn tài khoản Google vào máy** (Settings → Accounts) — popup native chọn tài khoản
  cần có ít nhất 1 tài khoản `@gmail.com` để `Selector(textContains: '@gmail.com')` khớp.
- **Mạng ổn định** — API OpenAlex trả về chậm; mọi bước chờ dữ liệu đặt timeout 30s.
- **App giữ phiên đăng nhập giữa các lần chạy** (suite không dùng `clearPackageData`), nên hầu hết test
  đi thẳng vào Home. Chỉ TC1 chủ động logout để dựng lại trạng thái chưa đăng nhập.
- Firebase đã cấu hình xong (`google-services.json`, SHA-1) — xem `FIREBASE_SETUP.md`.

---

## 8. Trạng thái kiểm tra

```
$ flutter analyze
3 issues found. (ran in 4.2s)
```

Cả 3 issue đều là **info có sẵn từ trước** trong `lib/`, không liên quan đến bộ test:

| Issue | Vị trí |
|---|---|
| `use_null_aware_elements` | `lib/firebase/analytics_service.dart:56` |
| `unnecessary_underscores` | `lib/screens/dashboard_screen.dart:140` (separatorBuilder của topic chips) |
| `unnecessary_underscores` | `lib/screens/trend_screen.dart:561` |

→ **Không phát sinh issue mới** từ `patrol_test/` hay từ 2 thay đổi trong `lib/`.

---

## 9. Việc còn tồn đọng (cần bạn quyết định)

**Thư mục `integration_test/` cũ vẫn còn 8 file test trùng mục đích.** Chúng dùng "demo mode" — nhánh
chỉ xuất hiện khi Firebase init **thất bại**, nên trên máy cấu hình đúng thì các test đó không đi qua
được màn Login. Patrol không chạy chúng (CLI mặc định đọc `patrol_test/`), nhưng để lại dễ gây nhầm khi
nộp bài. Cân nhắc xoá hoặc ghi chú rõ là code cũ.

**Luồng popup Google chưa được chạy thật để xác minh.** Nếu popup trên máy bạn có thêm bước xác nhận
("Continue"/"Tiếp tục") sau khi chọn tài khoản, `signInWithGoogle` sẽ cần thêm một lần `$.platform.tap`
nữa. Chạy TC1 một lần để kiểm chứng.
