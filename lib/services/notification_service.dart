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

  static const _channel = AndroidNotificationChannel(
    'ebostay_channel',
    'EBO Stay Notifications',
    description: 'Booking confirmations and reminders',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    // Setup local notifications
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id, _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });

    // Get & save token
    await _saveFcmToken();
    _fcm.onTokenRefresh.listen(_uploadToken);
  }

  Future<void> _saveFcmToken() async {
    final token = await _fcm.getToken();
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.fcmTokenKey);

    if (saved != token) {
      await prefs.setString(AppConstants.fcmTokenKey, token);
      await _uploadToken(token);
    }
  }

  Future<void> _uploadToken(String token) async {
    try {
      await ApiService().saveFcmToken(token);
    } catch (_) {}
  }
}
