import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

const _androidChannel = AndroidNotificationChannel(
  'default_channel',
  'Notificaciones generales',
  description: 'Anuncios, incidencias y otros avisos de Vecinoo.',
  importance: Importance.high,
);

/// Must be a top-level (or static) function: the platform relaunches the
/// engine in a separate isolate to run this when a push arrives while the
/// app is terminated or backgrounded, so it can't close over app state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('[push] background message: ${message.messageId}');
}

/// Wires up Firebase Cloud Messaging: requests permission, exposes the
/// device token, and routes foreground/tapped notifications.
///
/// Safe to call even before the Firebase project for vecinoo.app exists —
/// [initialize] just logs and returns instead of throwing, so it never
/// blocks app startup. Once `flutterfire configure` has filled in
/// `firebase_options.dart`, this starts working with no other changes.
class PushNotificationService {
  PushNotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  /// The current device's FCM token, once [initialize] has completed.
  /// Send this to the backend so it knows where to deliver pushes for
  /// this device (there is no `device_tokens` table yet — add one,
  /// plus an edge function that calls the FCM HTTP v1 API, to actually
  /// send notifications from the server).
  static String? deviceToken;

  static Future<void> initialize({
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onNotificationTap,
  }) async {
    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        '[push] skipped: firebase_options.dart is still a placeholder. '
        'Run `flutterfire configure` once the Firebase project for vecinoo.app exists.',
      );
      return;
    }

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[push] permission denied by user');
        return;
      }

      // On iOS, FCM's getToken() needs the APNS token first, and the OS
      // delivers that asynchronously right after requestPermission() —
      // calling getToken() immediately reliably loses this race, throwing
      // apns-token-not-set. Android has no such handshake.
      if (Platform.isIOS) {
        await _awaitApnsToken();
      }

      deviceToken = await _messaging.getToken();
      debugPrint('[push] device token: $deviceToken');
      _messaging.onTokenRefresh.listen((token) => deviceToken = token);

      await _initLocalNotifications();

      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('[push] foreground message: ${message.messageId}');
        // FCM never shows a system banner while the app is in the
        // foreground (both platforms) — without this, a foreground push
        // would only ever show up in this debug log.
        _showForegroundNotification(message);
        onForegroundMessage?.call(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('[push] notification tapped: ${message.messageId}');
        onNotificationTap?.call(message);
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        onNotificationTap?.call(initialMessage);
      }
    } catch (error, stackTrace) {
      debugPrint('[push] initialization failed: $error\n$stackTrace');
    }
  }

  static Future<void> _initLocalNotifications() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permissions were already requested above via _messaging.requestPermission();
        // asking again here would show a second, redundant system prompt.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  static void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<void> _awaitApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      if (await _messaging.getAPNSToken() != null) return;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('[push] APNS token never arrived after 5s; getToken() will likely fail');
  }
}
