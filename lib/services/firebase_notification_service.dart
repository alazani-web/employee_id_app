import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:supabase_flutter/supabase_flutter.dart';


class FirebaseNotificationService {
  FirebaseNotificationService._();

  static final FirebaseNotificationService instance =
      FirebaseNotificationService._();


  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;


  final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();


  // ============================================================
  // Initialize
  // ============================================================

  Future<void> initialize() async {

    await _requestPermission();

    await _initializeLocalNotification();

    await _saveDeviceToken();

    _listenForegroundMessages();

    _listenTokenRefresh();

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }



  // ============================================================
  // Permission
  // ============================================================

  Future<void> _requestPermission() async {

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }



  // ============================================================
  // Save Token in Supabase
  // ============================================================

  Future<void> _saveDeviceToken() async {

    final token =
        await _messaging.getToken();


    if (token == null) return;


    final user =
        Supabase.instance.client.auth.currentUser;


    if (user == null) return;


    await Supabase.instance.client
        .from('device_tokens')
        .upsert(
      {
        'user_id': user.id,
        'token': token,
        'platform': Platform.operatingSystem,
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      onConflict: 'token',
    );
  }




  // ============================================================
  // Token Refresh
  // ============================================================

  void _listenTokenRefresh() {

    _messaging.onTokenRefresh.listen(
      (newToken) async {

        final user =
            Supabase.instance.client.auth.currentUser;


        if (user == null) return;


        await Supabase.instance.client
            .from('device_tokens')
            .upsert(
          {
            'user_id': user.id,
            'token': newToken,
            'platform':
                Platform.operatingSystem,
            'updated_at':
                DateTime.now()
                    .toIso8601String(),
          },
          onConflict: 'token',
        );
      },
    );
  }




  // ============================================================
  // Foreground Messages
  // ============================================================

  void _listenForegroundMessages() {

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {

        final notification =
            message.notification;


        if (notification == null) return;


        await _localNotifications.show(
          id: notification.hashCode,
          title:
              notification.title ?? 'تنبيه',
          body:
              notification.body ?? '',
          notificationDetails:
              const NotificationDetails(
            android:
                AndroidNotificationDetails(
              'identity_alerts',
              'Identity Alerts',
              channelDescription:
                  'تنبيهات انتهاء الهويات والوثائق',
              importance:
                  Importance.high,
              priority:
                  Priority.high,
            ),
          ),
        );
      },
    );
  }





  // ============================================================
  // Local Notification Setup
  // ============================================================

  Future<void> _initializeLocalNotification() async {


    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );


    const settings =
        InitializationSettings(
      android:
          androidSettings,
    );


    await _localNotifications.initialize(
      settings: settings,
    );
  }

}




// ============================================================
// Background Handler
// ============================================================

@pragma('vm:entry-point')
Future<void>
firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {

  // لا تضف Provider أو Supabase هنا
  // يعمل داخل isolate مستقل

}