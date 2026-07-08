import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

/// A single push notification received via FCM (lab §4.8 "Notification Center").
class AppNotification {
  final String title;
  final String body;
  final DateTime receivedAt;

  AppNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
  });
}

/// Top-level background handler (required by FCM to be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 BG message: ${message.notification?.title}');
}

/// Wraps Firebase Cloud Messaging: permission, token, and an in-memory feed
/// of received notifications that the Notification Center displays.
class MessagingService extends ChangeNotifier {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  String? _token;
  String? get token => _token;

  bool _initialized = false;

  FirebaseMessaging? get _fm =>
      firebaseReady ? FirebaseMessaging.instance : null;

  Future<void> init() async {
    if (!firebaseReady || _initialized) return;
    _initialized = true;
    try {
      final fm = _fm!;
      await fm.requestPermission(alert: true, badge: true, sound: true);

      _token = await fm.getToken();
      debugPrint('🔑 FCM token: $_token');

      // Foreground messages → add to the feed.
      FirebaseMessaging.onMessage.listen(_onMessage);

      // App opened from a notification.
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessage);

      // Message that launched the app from terminated state.
      final initial = await fm.getInitialMessage();
      if (initial != null) _onMessage(initial);
    } catch (e) {
      debugPrint('Messaging init error: $e');
    }
  }

  void _onMessage(RemoteMessage message) {
    final n = message.notification;
    _notifications.insert(
      0,
      AppNotification(
        title: n?.title ?? message.data['title'] ?? 'Thông báo',
        body: n?.body ?? message.data['body'] ?? '',
        receivedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Adds a local sample notification so the Notification Center can be
  /// demonstrated even without sending a real FCM push.
  void addSample() {
    _notifications.insert(
      0,
      AppNotification(
        title: 'Xu hướng nghiên cứu mới',
        body: 'Chủ đề "Machine Learning" đang tăng mạnh trong năm nay.',
        receivedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
