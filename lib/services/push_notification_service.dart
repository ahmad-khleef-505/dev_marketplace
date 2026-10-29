import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> notificationMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

const _webVapidKey = String.fromEnvironment('FCM_VAPID_KEY');
const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'إشعارات مهمة',
  description: 'إشعارات الرسائل والطلبات المهمة.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Received background push message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  String? _activeUid;
  bool _initialized = false;

  static bool get isMessagingPlatformSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings: initializationSettings);
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    if (!isMessagingPlatformSupported) {
      debugPrint('Firebase Messaging is not supported on this platform.');
      return;
    }

    final supported = await FirebaseMessaging.instance.isSupported();
    if (!supported) {
      debugPrint('Firebase Messaging is not supported on this platform.');
      return;
    }

    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundMessage,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Foreground push listener failed: $error');
      },
    );
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _configureForUser,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Push notification auth listener failed: $error');
      },
    );
  }

  Future<void> _configureForUser(User? user) async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _activeUid = user?.uid;
    if (user == null) return;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _showSetupMessage('لم يتم منح إذن الإشعارات.');
        return;
      }

      if (kIsWeb && _webVapidKey.isEmpty) {
        _showSetupMessage(
          'للتفعيل على الويب، أضف مفتاح FCM_VAPID_KEY عند تشغيل التطبيق.',
        );
        return;
      }

      // ignore: deprecated_member_use
      _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (refreshedToken) => _saveToken(user.uid, refreshedToken),
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('FCM token refresh listener failed: $error');
        },
      );

      // FCM's current Flutter plugin still exposes getToken for the device token
      // required by the app's notification sender.
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
        serviceWorkerScriptPath: kIsWeb ? 'firebase-messaging-sw.js' : null,
      );
      if (token != null && token.isNotEmpty) {
        await _saveToken(user.uid, token);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to configure push notifications: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showSetupMessage('تعذر تفعيل الإشعارات: $error');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    if (_activeUid != uid) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'إشعار جديد';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;

    if (kIsWeb) {
      notificationMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              [title, body].where((text) => text.isNotEmpty).join('\n'),
            ),
          ),
        );
      return;
    }

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
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

  void _showSetupMessage(String message) {
    notificationMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
  }
}
