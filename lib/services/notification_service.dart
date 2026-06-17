// lib/services/notification_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _fcm = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'ebostay_channel';
  static const _channelName = 'EBO Stay Notifications';
  static const _channelDesc = 'Booking confirmations and reminders';

  static const _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Android init settings — v17 mein onDidReceiveNotificationResponse
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Notification tap handle karo yahan
      },
    );

    // Android notification channel create karo
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    // FCM token save karo
    await _saveFcmToken();
    _fcm.onTokenRefresh.listen(_uploadToken);
  }

  Future<void> _saveFcmToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(AppConstants.fcmTokenKey);

      if (saved != token) {
        await prefs.setString(AppConstants.fcmTokenKey, token);
        await _uploadToken(token);
      }
    } catch (_) {}
  }

  Future<void> _uploadToken(String token) async {
    try {
      await ApiService().saveFcmToken(token);
    } catch (_) {}
  }
}
