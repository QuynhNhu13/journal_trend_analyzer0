# Kiến trúc — MVVM (Model–View–ViewModel)

App tuân theo MVVM với **Provider** làm cơ chế binding giữa ViewModel và View.

```
lib/
├── models/        # Model — lớp dữ liệu thuần (Publication, Author, DashboardSummary…)
├── services/      # Service — nguồn dữ liệu ngoài (OpenAlexService gọi API, storage cục bộ)
├── firebase/      # Service — bọc từng dịch vụ Firebase (auth, analytics, storage, messaging, remote config, crashlytics)
├── viewmodels/    # ViewModel — ChangeNotifier: giữ state + logic nghiệp vụ, không có widget
├── providers/     # ViewModel (kế thừa từ Lab 02) — cũng là ChangeNotifier cho từng màn dữ liệu
├── screens/       # View — UI, chỉ đọc state từ ViewModel qua context.watch/read
├── widgets/       # View — widget tái sử dụng (auth_gate, cards, charts…)
├── theme/         # Design system (màu, spacing, ThemeData)
├── l10n/          # Đa ngôn ngữ (EN/VI)
└── utils/         # Tiện ích dùng chung
```

## Luồng dữ liệu (một chiều)

```
View (screens/widgets)
   │  đọc state:  context.watch<VM>()
   │  gọi action: context.read<VM>().doSomething()
   ▼
ViewModel (viewmodels/ + providers/)   ← ChangeNotifier, notifyListeners()
   │  gọi
   ▼
Service (services/ + firebase/)        ← OpenAlex API, Firebase SDK
   │  trả về
   ▼
Model (models/)                        ← dữ liệu thuần
```

## Nguyên tắc

- **View không chứa logic nghiệp vụ.** Màn hình chỉ render state và phát action.
- **ViewModel không import `package:flutter/material.dart`** (chỉ `foundation` cho `ChangeNotifier`) — tách UI khỏi logic.
- **Service không biết gì về UI/state.** Trả về Model hoặc ném lỗi; ViewModel quyết định xử lý.
- Mọi lời gọi Firebase đều kiểm tra cờ `firebaseReady` (xem `firebase/firebase_bootstrap.dart`) để an toàn khi chưa cấu hình.

> Ghi chú: thư mục `providers/` là lớp ViewModel có sẵn từ Lab 02. Từ Lab 03,
> các ViewModel mới (ví dụ `AuthViewModel`) đặt trong `viewmodels/`. Cả hai
> đều là ChangeNotifier và đóng vai trò ViewModel trong MVVM.
