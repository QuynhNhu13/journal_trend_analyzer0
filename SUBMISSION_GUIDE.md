# Hướng dẫn hoàn tất & nộp bài — PRM393 Lab 03

Code đã xong. Tài liệu này liệt kê **những việc còn lại của bạn** (cấu hình, chạy, chụp ảnh, viết báo cáo, quay video) — phần Claude không làm thay được.

---

## 0. Bắt buộc trước tiên: cấu hình Firebase
Làm theo **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)**. Không có bước này thì Google Sign-In, Storage, FCM, Remote Config, Crashlytics đều không chạy thật.

Kiểm tra nhanh sau khi xong:
```powershell
flutter run -d emulator-5554
```
- Màn Login → bấm **Đăng nhập với Google** → chọn tài khoản → vào Home.
- 4 tab dưới cùng: Home · Journals · Keywords · Profile.

---

## 1. Firebase Analytics — thu thập bằng chứng (25% điểm)
Các event đã được code sẵn (xem `lib/firebase/analytics_service.dart`):
`login`, `search_topic`, `view_publication`, `view_journal`, `view_keyword`, `export_pdf`, `logout`.

Cách xem để chụp ảnh báo cáo:
- **DebugView (khuyên dùng):**
  ```powershell
  adb shell setprop debug.firebase.analytics.app com.example.journal_trend_analyzer
  ```
  Rồi mở Firebase Console → Analytics → **DebugView**, thao tác trong app và chụp các event hiện ra.
- Hoặc Console → Analytics → Events (dữ liệu trễ tới 24h).

---

## 2. Patrol E2E tests (15% điểm)
Đã viết sẵn 11 test case trong `patrol_test/` (7 file + `test_helpers.dart`).
Chi tiết đầy đủ: xem `PATROL_E2E_SUMMARY.md`.

Cài Patrol CLI và chạy:
```powershell
dart pub global activate patrol_cli
patrol test -d RF8N5140DBL                                # chạy tất cả
patrol test -t patrol_test/journal_test.dart -d RF8N5140DBL   # chạy 1 file
```
> Lưu ý: test chạy trên **điện thoại Android thật** đã đăng nhập sẵn tài khoản Google (Settings → Accounts) — TC1 dùng popup native để sign-in thật, không dùng chế độ demo. Mọi finder bám **ValueKey** trong `lib/utils/widget_keys.dart`, không theo text, nên đổi ngôn ngữ EN/VI không làm vỡ test.

**Bằng chứng cần nộp:** screenshot mã nguồn test, screenshot lúc chạy (pass/fail), bảng tóm tắt kết quả, giải thích ngắn từng test.

Bảng test case:
| # | File | Kịch bản |
|---|---|---|
| 1 | auth_test.dart | Google Sign-In → Home |
| 2 | publication_test.dart | Tìm chủ đề → có kết quả |
| 3 | publication_test.dart | Mở chi tiết công bố |
| 4 | navigation_test.dart | Tab Journals → thống kê + danh sách |
| 5 | journal_test.dart | Chi tiết tạp chí |
| 6 | navigation_test.dart | Tab Keywords → thống kê + danh sách |
| 7 | keyword_test.dart | Chi tiết từ khóa |
| 8 | navigation_test.dart | Tab Profile → thông tin user |
| 9 | export_test.dart | Xuất PDF → upload Storage |
| 10 | remote_config_test.dart | Hiển thị Remote Config |
| 11 | auth_test.dart | Đăng xuất → Login |

---

## 3. AI-Assisted Code Review (5% điểm)
Dùng một trong các công cụ: **GitHub Copilot Code Review, CodeRabbit, SonarQube, Kodus AI**.
- Cách nhanh nhất: mở Pull Request trên GitHub và bật **CodeRabbit** (miễn phí cho public repo) hoặc **Copilot code review**.
- Phải nêu **≥ 3 vấn đề/cảnh báo/code smell**, xử lý những cái hợp lý, và **chụp màn hình** quá trình + giải thích ngắn vào báo cáo.

---

## 4. Báo cáo (5–10 trang)
Bố cục gợi ý (đã có sẵn nhiều nội dung trong repo để bạn trích):
1. Tổng quan dự án
2. Kiến trúc hệ thống + **MVVM** → trích từ [ARCHITECTURE.md](ARCHITECTURE.md)
3. Thiết kế tích hợp Firebase (6 dịch vụ) → trích từ `lib/firebase/`
4. Screenshot các tính năng
5. Firebase Analytics events (ảnh DebugView)
6. Crashlytics report (ảnh Console sau khi bấm Test crash)
7. Remote Config demo (ảnh tab Profile + Console)
8. Kịch bản & kết quả Patrol
9. Kết quả AI code review
10. Khó khăn gặp phải + Bài học

---

## 5. Video demo (5–10 phút)
Quay lần lượt: Google Sign-In → tìm chủ đề → chi tiết công bố → phân tích tạp chí → phân tích từ khóa → tác giả → xuất & upload PDF → push notification (gửi test từ Console) → Remote Config → Crashlytics test → chạy Patrol → AI code review.

---

## 6. Nộp bài
- Repo GitHub đặt tên: **`PRM393_Lab03_<StudentID>`**
- Gồm: source code, **file cấu hình Firebase** (`google-services.json`, `firebase_options.dart`), Patrol tests, assets.
- Kèm báo cáo + link video.

> ⚠️ Lưu ý bảo mật: `google-services.json` chứa khóa cấu hình. Với bài lab thì commit là chấp nhận được, nhưng project thật nên đưa vào `.gitignore`.
