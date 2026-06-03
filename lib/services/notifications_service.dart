import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/globals.dart';
import 'api_client.dart';
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

  static const _trustedDomains = {'medverify.app', 'fdaghana.gov.gh'};

  // Routes that FCM payloads are allowed to navigate to.
  // Excluded: /results (requires arguments → crash), /scanner (unexpected UX),
  // /welcome (resets onboarding), / (root), /manual (argument-sensitive).
  static const _allowedRoutes = {
    '/dashboard',
    '/history',
    '/info',
    '/feedback',
    '/how_it_works',
    '/privacy',
    '/about',
  };
  static const _kNotificationsEnabled = 'notifications_topics_enabled';
  static const _topics = ['news', 'info'];

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

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kNotificationsEnabled) ?? true) {
      await subscribeToTopics();
    }

    // 1. Upload this token to your server immediately
    await uploadTokenToServer(fCMToken);

    // Listen for token refreshes.
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      uploadTokenToServer(newToken).catchError((_) {});
    });

    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Message tap handlers and foreground banner are set up in these two
    // methods — registering them here too would create duplicate listeners.
    initPushNotifications();
    initLocalNotifications();
  }

  /// Subscribes to all topics and persists the preference. Call this when the
  /// user enables topic notifications in settings.
  Future<void> subscribeToTopics() async {
    for (final topic in _topics) {
      await _firebaseMessaging.subscribeToTopic(topic);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, true);
  }

  /// Unsubscribes from all topics and persists the preference. Call this when
  /// the user disables topic notifications in settings.
  Future<void> unsubscribeFromTopics() async {
    for (final topic in _topics) {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, false);
  }

  Future<void> uploadTokenToServer(String? token) async {
    if (token == null) return;

    try {
      final accessToken =
          await DeviceAuthService.instance.getValidAccessToken();
      await ApiClient.instance.dio.patch(
        '/v1/device/fcm-token',
        data: {'fcm_token': token},
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
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

      // Use hashCode as a per-notification ID so concurrent notifications
      // don't silently overwrite each other in the system tray.
      _localNotifications.show(
        id: notification.hashCode,
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
        payload: jsonEncode(message.data),
      );
    });
  }

  Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _localNotifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (payload) {
        if (payload.payload == null) return;
        try {
          final message =
              RemoteMessage.fromMap(jsonDecode(payload.payload!));
          handleMessage(message);
        } catch (_) {}
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

      // Only allow HTTPS links to known trusted domains.
      if (uri.scheme != 'https') return;
      if (!_trustedDomains.contains(uri.host)) return;

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (data.containsKey('route')) {
      final route = data['route'] as String?;
      if (route != null && _allowedRoutes.contains(route)) {
        navigatorKey.currentState?.pushNamed(route);
      }
    }
  }
}
