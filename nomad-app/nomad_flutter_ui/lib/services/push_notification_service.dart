import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'local_storage_service.dart';

// Background message handler (must be top-level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await LocalStorageService().init();
  await PushNotificationService()._showLocalNotification(message);
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _api = ApiService();
  final LocalStorageService _storage = LocalStorageService();

  Function(RemoteMessage)? onMessageOpened;
  Function(RemoteMessage)? onForegroundMessage;

  Future<void> initialize() async {
    // Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
        final payload = response.payload;
        if (payload != null) {
          final data = jsonDecode(payload);
          _handleDeepLink(data);
        }
      },
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      onForegroundMessage?.call(message);
    });

    // When app opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onMessageOpened?.call(message);
    });

    // Get and save FCM token
    await _updateFcmToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((String token) async {
      await _storage.saveFcmToken(token);
      await _sendTokenToServer(token);
    });
  }

  Future<void> _updateFcmToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _storage.saveFcmToken(token);
      await _sendTokenToServer(token);
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      await _api.post('/push/token', body: {
        'token': token,
        'deviceType': _getDeviceType(),
        'deviceId': await _getDeviceId(),
      });
    } catch (e) {
      // Token will be sent on next API call
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'nomad_main_channel',
      'NOMAD Notifications',
      channelDescription: 'Main notification channel for NOMAD',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );

    // Cache notification locally
    await _storage.cacheNotification({
      'id': message.messageId ?? DateTime.now().toIso8601String(),
      'title': notification.title,
      'body': notification.body,
      'type': message.data['type'] ?? 'general',
      'data': message.data,
    });
  }

  void _handleDeepLink(Map<String, dynamic> data) {
    final String? screen = data['screen'];
    final String? id = data['id'];

    // Navigation will be handled by the app navigator
    // This is a simplified version
    debugPrint('Deep link: screen=$screen, id=$id');
  }

  String _getDeviceType() {
    // Simplified - use device_info_plus in production
    return 'android';
  }

  Future<String> _getDeviceId() async {
    // Simplified - use device_info_plus or unique identifier
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    await _storage.saveFcmToken('');
  }
}
