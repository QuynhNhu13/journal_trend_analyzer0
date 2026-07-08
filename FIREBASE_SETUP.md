# Firebase Setup — Việc BẠN phải tự làm

> Những bước dưới đây cần **tài khoản Google của bạn** nên Claude không làm hộ được.
> Làm theo đúng thứ tự. `applicationId` của app là: **`com.example.journal_trend_analyzer`**

---

## Bước 1 — Cài công cụ (một lần)

```powershell
# Firebase CLI (cần Node.js). Nếu chưa có Node: cài tại https://nodejs.org
npm install -g firebase-tools

# FlutterFire CLI
dart pub global activate flutterfire_cli

# Đăng nhập Firebase bằng tài khoản Google của bạn
firebase login
```

> Nếu lệnh `flutterfire` báo "not recognized", thêm vào PATH:
> `C:\Users\LENOVO\AppData\Local\Pub\Cache\bin`

---

## Bước 2 — Tạo project Firebase

1. Vào https://console.firebase.google.com → **Add project**
2. Đặt tên (ví dụ `journal-trend-analyzer`) → Continue → tắt/ bật Analytics tuỳ ý → Create.

---

## Bước 3 — Sinh file cấu hình (QUAN TRỌNG NHẤT)

Chạy tại thư mục gốc project (`journal_trend_analyzer`):

```powershell
flutterfire configure
```

- Chọn project vừa tạo.
- Chọn platform: **Android** (và iOS nếu muốn).
- Xác nhận applicationId `com.example.journal_trend_analyzer`.

Lệnh này sẽ tự tạo:
- `lib/firebase_options.dart`
- `android/app/google-services.json`

> ✅ Sau bước này, báo Claude biết để wire code vào chạy thật.

---

## Bước 4 — Đăng ký SHA-1 (BẮT BUỘC cho Google Sign-In)

Google Sign-In **sẽ lỗi** nếu thiếu SHA-1. Lấy SHA-1 của debug keystore:

```powershell
cd android
./gradlew signingReport
```

Tìm dòng `SHA1:` trong mục `Variant: debug`. Copy giá trị đó.

Rồi vào **Firebase Console → Project Settings (⚙️) → mục "Your apps" → chọn app Android → Add fingerprint** → dán SHA-1 → Save.

Sau đó **tải lại `google-services.json`** mới và thay vào `android/app/`.

---

## Bước 5 — Bật các dịch vụ trong Console

| Dịch vụ | Nơi bật |
|---|---|
| **Authentication** | Build → Authentication → Get started → Sign-in method → bật **Google** → chọn support email → Save |
| **Storage** | Build → Storage → Get started → chọn location → Start in **test mode** (cho lab) |
| **Cloud Messaging (FCM)** | Đã bật sẵn khi tạo project. Không cần thao tác. |
| **Analytics** | Build → Analytics → bật (nếu lúc tạo project chưa bật) |
| **Crashlytics** | Build → Crashlytics → Get started (dữ liệu hiện sau lần crash đầu tiên) |
| **Remote Config** | Build → Remote Config → tạo 2 tham số dưới đây |

### Tham số Remote Config cần tạo (Bước 5 - Remote Config)

| Parameter key | Type | Default value |
|---|---|---|
| `max_journals_displayed` | Number | `10` |
| `max_keywords_displayed` | Number | `20` |

→ Sau khi thêm, bấm **Publish changes**.

---

## Bước 6 — Gửi FCM test (để demo Notification)

Console → Messaging → **Create your first campaign** → Firebase Notification messages →
nhập tiêu đề/nội dung → Send test message → dán **FCM token** (app sẽ in token ra log khi chạy).

---

## Tóm tắt: sau khi làm xong, bạn phải có

- [ ] `lib/firebase_options.dart` tồn tại
- [ ] `android/app/google-services.json` tồn tại (đã có SHA-1)
- [ ] Authentication → Google: **Enabled**
- [ ] Storage: đã khởi tạo
- [ ] Remote Config: 2 tham số đã **Published**
- [ ] Crashlytics + Analytics: đã Get started

Khi đủ các mục trên, app sẽ chạy được đầy đủ tính năng Firebase.
