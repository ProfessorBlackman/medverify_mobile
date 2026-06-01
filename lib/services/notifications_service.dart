import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:medverify_mobile/utils/variables.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../utils/globals.dart';
import 'device_auth_service.dart';

// ⚠️ TOP-LEVEL FUNCTION: Must be outside the class and annotated
// This handles messages when the app is completely closed (Terminated)
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    print('Background Message: ${message.notification?.title}');
    print('Payload: ${message.data}');
  }
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  // Setup for local notifications (to show banners when app is open)
  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.defaultImportance,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // 1. Request Permission (Required for Android 13+ & iOS)
    await _firebaseMessaging.requestPermission();

    // 2. Fetch the FCM Token
    final fCMToken = await _firebaseMessaging.getToken();

    await _firebaseMessaging.subscribeToTopic('news');
    await _firebaseMessaging.subscribeToTopic('info');

    // 1. Upload this token to your server immediately
    await uploadTokenToServer(fCMToken);

    // 2. Listen for refreshes (Crucial!)
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      uploadTokenToServer(newToken);
    });
    // 1. APP TERMINATED: User taps notification while app is completely closed
    _firebaseMessaging.getInitialMessage().then(handleMessage);

    // 2. APP IN BACKGROUND: User taps notification while app is minimized
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // 3. Initialize background settings
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // 4. Initialize local notifications
    initPushNotifications();
    initLocalNotifications();
  }

  Future<void> uploadTokenToServer(String? token) async {
    if (token == null) return;

    try {
      final accessToken =
          await DeviceAuthService.instance.getValidAccessToken();
      await http.patch(
        Uri.parse('$backendUrl/device/fcm-token'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (_) {
      // Non-fatal: FCM token upload failing must not block the app
    }
  }

  Future<void> initPushNotifications() async {
    // Handle notification if the app was terminated and now opened via notification
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // Handle notification if the app is in background and opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // Handle notification when the app is in FOREGROUND (Stream listener)
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      // Manually show a local notification
      _localNotifications.show(
        // notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data), id: 0,
      );
    });
  }

  Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (payload) {
        final message = RemoteMessage.fromMap(jsonDecode(payload.payload!));
        handleMessage(message);
      },
    );

    // Create the channel on Android
    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await platform?.createNotificationChannel(_androidChannel);
  }

  void handleMessage(RemoteMessage? message) async {
    if (message == null) return;

    final data = message.data;

    if (data.containsKey('url')) {
      final urlString = data['url'] as String?;
      if (urlString == null || urlString.isEmpty) return;

      final uri = Uri.tryParse(urlString);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) return;

      // Only allow safe HTTPS links to prevent phishing via FCM payloads.
      if (uri.scheme != 'https') return;

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (data.containsKey('route')) {
      final route = data['route'] as String?;
      if (route != null && route.startsWith('/')) {
        navigatorKey.currentState?.pushNamed(route);
      }
    }
  }
}
