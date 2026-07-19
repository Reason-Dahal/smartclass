import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../network/dio_client.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Call this once, after a successful login — requests permission,
  // obtains the FCM token, and registers it with the backend so
  // this device can actually receive pushes.
  static Future<void> initialize() async {
    // Android 13+ requires explicit runtime permission for notifications —
    // older Android versions grant it automatically, but requesting is
    // harmless either way.
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _initLocalNotifications();

    final token = await _messaging.getToken();
    if (token != null) {
      await _registerTokenWithBackend(token);
    }

    // If Firebase issues a new token later (token refresh, reinstall,
    // etc.), send the updated one automatically.
    _messaging.onTokenRefresh.listen(_registerTokenWithBackend);

    // Foreground messages don't automatically show a system banner on
    // Android — this listener displays one manually using
    // flutter_local_notifications whenever a push arrives while the
    // app is open and in view.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings: initSettings);
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'smartclass_default',
      'SmartClass Notifications',
      channelDescription: 'Assignment, note, and grading updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'SmartClass',
      body: message.notification?.body ?? '',
      notificationDetails: details,
    );
  }

  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      await DioClient.instance.post(
        '/auth/fcm-token',
        data: {'fcmToken': token},
      );
    } catch (e) {
      // Non-critical — if this fails, the user simply won't receive
      // push notifications until the next successful registration
      // attempt (e.g. next login). Never let this crash the app.
    }
  }
}
