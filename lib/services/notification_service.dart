import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _fcmToken;

  static Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('📱 Notification permission: ${settings.authorizationStatus}');

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Register device with backend
      if (_fcmToken != null) {
        await _registerDevice(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _registerDevice(newToken);
      });

      // Configure local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotifications.initialize(initSettings);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle when user taps a notification (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle when app was terminated and user taps notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      print('✅ Notification service fully initialized');
    } catch (e) {
      print('⚠️ Notification service initialization error: $e');
    }
  }

  static Future<void> _registerDevice(String token) async {
    try {
      final authHeaders = await ApiService.headers();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/devices/register'),
        headers: authHeaders,
        body: jsonEncode({
          'token': token,
          'platform': 'android',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Device registered for push notifications');
      } else {
        print('⚠️ Device registration failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('⚠️ Device registration error: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Foreground notification: ${message.notification?.title}');
    print('📬 Data: ${message.data}');

    _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
    );
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'exora_channel',
        'Exora Notifications',
        channelDescription: 'Notifications for Exora app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );

      print('✅ Local notification shown: $title');
    } catch (e) {
      print('⚠️ Failed to show notification: $e');
    }
  }

  static void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped: ${message.data}');
    // You can navigate based on data if needed
  }

  static Future<int> getUnreadCount() async {
    try {
      final authHeaders = await ApiService.headers();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/notifications?unread=true'),
        headers: authHeaders,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data is List) ? data.length : 0;
      }
    } catch (e) {
      print('⚠️ Failed to fetch unread count: $e');
    }
    return 0;
  }
}