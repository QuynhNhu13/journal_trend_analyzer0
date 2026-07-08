import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'messaging_service.dart';
import 'remote_config_service.dart';

/// Trạng thái Firebase đã init thành công hay chưa.
/// Toàn bộ code Firebase khác phải kiểm tra cờ này trước khi gọi service,
/// để app không crash khi chưa cấu hình Firebase.
bool firebaseReady = false;

/// Khởi tạo Firebase + các dịch vụ nền (Crashlytics, Remote Config, Messaging).
/// Bọc try/catch để app vẫn chạy được khi bạn chưa hoàn tất `flutterfire configure`.
Future<void> bootstrapFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
    debugPrint('✅ Firebase initialized.');

    // Crashlytics & Messaging (FCM) don't support Flutter web — skip them there
    // so a web run still initializes Firebase (Auth/Storage/Analytics/Remote Config).
    if (!kIsWeb) {
      // ── Crashlytics: bắt mọi lỗi Flutter chưa xử lý ──
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      // Collect crashes even in debug so the Crashlytics demo works during dev.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // ── Messaging (FCM) ──
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await MessagingService.instance.init();
    }

    // ── Remote Config (works on web too) ──
    await RemoteConfigService.instance.init();
  } catch (e) {
    firebaseReady = false;
    debugPrint(
      '⚠️ Firebase chưa sẵn sàng ($e). '
      'App vẫn chạy nhưng các tính năng Firebase bị tắt. '
      'Xem FIREBASE_SETUP.md để cấu hình.',
    );
  }
}
