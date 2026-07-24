import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_bootstrap.dart';
import 'user_data_service.dart';

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
///
/// When the app is in the background or terminated, FCM itself displays the
/// system notification, so we must NOT show a local one here (that would
/// duplicate it). We only log.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 BG message: ${message.notification?.title}');
}

/// Wraps Firebase Cloud Messaging: permission, token, an in-memory feed of
/// received notifications that the Notification Center displays, and — new —
/// a heads-up banner shown via [flutter_local_notifications] when a message
/// arrives while the app is in the foreground.
class MessagingService extends ChangeNotifier {
  MessagingService._();
  static final MessagingService instance = MessagingService._();

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  String? _token;
  String? get token => _token;

  bool _initialized = false;

  /// Shows local (heads-up) notifications while the app is in the foreground.
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// High-importance channel so foreground notifications pop up as a banner
  /// instead of sitting silently in the tray.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Thông báo quan trọng',
    description: 'Kênh cho thông báo đẩy quan trọng (FCM).',
    importance: Importance.max,
  );

  /// Set when the user taps a notification, so the shell can switch to the
  /// Notification Center (Profile tab). Consumed via
  /// [takeOpenNotificationCenterRequest].
  bool _openNotificationCenterRequested = false;

  FirebaseMessaging? get _fm =>
      firebaseReady ? FirebaseMessaging.instance : null;

  Future<void> init() async {
    if (!firebaseReady || _initialized) return;
    try {
      final fm = _fm!;

      // Notification permission (iOS + Android 13+ POST_NOTIFICATIONS).
      await fm.requestPermission(alert: true, badge: true, sound: true);

      await _setupLocalNotifications();

      _token = await fm.getToken();
      debugPrint('🔑 FCM token: $_token');

      // Mirror the token to Firestore (users/{uid}.fcmToken) so the web admin can
      // target this device. If no user is signed in yet, this no-ops; the token
      // is re-persisted after login via [persistTokenForCurrentUser], and any
      // future rotation is caught by onTokenRefresh below.
      if (_token != null) {
        unawaited(UserDataService.instance.saveFcmToken(_token!));
      }
      fm.onTokenRefresh.listen((refreshed) {
        _token = refreshed;
        unawaited(UserDataService.instance.saveFcmToken(refreshed));
      });

      // Foreground → add to the feed AND show a heads-up banner ourselves
      // (FCM does not display anything while the app is in the foreground).
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // Tapped while the app was in the background → feed + open the center.
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped);

      // Launched from a terminated state by tapping a notification.
      final initial = await fm.getInitialMessage();
      if (initial != null) _onNotificationTapped(initial);

      // Only latch as initialized once the full setup succeeded, so a failed
      // attempt can be retried later in the same session.
      _initialized = true;
    } catch (e) {
      debugPrint('Messaging init error: $e');
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: darwinInit);

    // Tapping the foreground banner opens the Notification Center.
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) => requestOpenNotificationCenter(),
    );

    final android =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    // Create the high-importance channel and request Android 13+ permission.
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();
  }

  void _onForegroundMessage(RemoteMessage message) {
    _addToFeed(message);
    _showBanner(message);
  }

  void _onNotificationTapped(RemoteMessage message) {
    _addToFeed(message);
    requestOpenNotificationCenter();
  }

  /// Shows a heads-up banner for a foreground message. Only ever called from the
  /// `onMessage` (foreground) handler, so it never duplicates the notification
  /// FCM already shows in the background/terminated states.
  void _showBanner(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? message.data['title'] ?? 'Thông báo';
    final body = n?.body ?? message.data['body'] ?? '';

    _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _addToFeed(RemoteMessage message) {
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

  /// Re-writes the current FCM token to the signed-in user's profile. Called
  /// right after login, since the token is usually obtained at startup (before
  /// a user exists) and would otherwise never attach to that user.
  Future<void> persistTokenForCurrentUser() async {
    final current = _token;
    if (current != null) {
      await UserDataService.instance.saveFcmToken(current);
    }
  }

  // ── Tab-navigation signal (consumed by MainShell) ──

  /// Flags that the Notification Center should be opened, then notifies
  /// listeners so the shell can react.
  void requestOpenNotificationCenter() {
    _openNotificationCenterRequested = true;
    notifyListeners();
  }

  /// Returns true once (and clears the flag) if an "open Notification Center"
  /// request is pending.
  bool takeOpenNotificationCenterRequest() {
    if (!_openNotificationCenterRequested) return false;
    _openNotificationCenterRequested = false;
    return true;
  }
}
