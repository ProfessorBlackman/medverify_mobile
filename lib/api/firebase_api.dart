import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:medverify_mobile/utils/variables.dart';
import 'dart:convert';

import '../utils/user_identification.dart';

// ⚠️ TOP-LEVEL FUNCTION: Must be outside the class and annotated
// This handles messages when the app is completely closed (Terminated)
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Background Message: ${message.notification?.title}');
  print('Payload: ${message.data}');
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
    print('FCM Token: $fCMToken');

    // 1. Upload this token to your server immediately
    await uploadTokenToServer(fCMToken);

    // 2. Listen for refreshes (Crucial!)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      uploadTokenToServer(newToken);
    });

    // 3. Initialize background settings
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // 4. Initialize local notifications
    initPushNotifications();
    initLocalNotifications();
  }

  Future<void> uploadTokenToServer(String? token) async {
    if (token == null) return;

    // get user's unique identifier
    String userId = await getUserId();

    await http.post(
      Uri.parse('$backendUrl/register-user'),
      headers: {
        'Content-Type': 'application/json',
        'User-ID': userId,  // Attach the UUID here
      },
      body: jsonEncode({
        token: token
      }),
    );

    print("Token saved to server: $token");
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
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
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
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (payload) {
        final message = RemoteMessage.fromMap(jsonDecode(payload.payload!));
        handleMessage(message);
      },
    );

    // Create the channel on Android
    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    // Logic to navigate to a specific screen when notification is tapped
    // navigatorKey.currentState?.pushNamed('/notification_screen', arguments: message);
  }
}