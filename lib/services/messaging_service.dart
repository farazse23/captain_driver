import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'notification_service.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // ignore: unused_field
  final NotificationService _notificationService = NotificationService();

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize messaging
  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission for notifications');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      print('FCM Token obtained: $token');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _saveTokenToFirestore(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Show local notification when app is in foreground
        _showLocalNotification(message);
      }
    });

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      print('Message data: ${message.data}');

      // Navigate to notifications screen based on notification type
      if (message.data.containsKey('type')) {
        print('Notification type: ${message.data['type']}');
      }
    });
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/truck_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'driver_notifications',
      'Driver Notifications',
      description: 'Notifications for driver app',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'driver_notifications',
          'Driver Notifications',
          channelDescription: 'Notifications for driver app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/truck_icon',
          color: Color(0xFFFF6B35),
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');
    // Handle navigation based on payload
  }

  // Save token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Cannot save FCM token: No authenticated user');
        return;
      }

      print('Saving FCM token for user: ${user.email}');

      // Get driver document ID
      final driverQuery = await _firestore
          .collection('drivers')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (driverQuery.docs.isNotEmpty) {
        final driverDocId = driverQuery.docs.first.id;
        print('Found driver document: $driverDocId');

        // Save token under driver document with better validation
        await _firestore
            .collection('drivers')
            .doc(driverDocId)
            .collection('tokens')
            .doc(token)
            .set({
              'token': token,
              'platform': Platform.isIOS ? 'ios' : 'android',
              'createdAt': FieldValue.serverTimestamp(),
              'lastUsed': FieldValue.serverTimestamp(),
              'appVersion': '1.0.0', // Add app version for debugging
              'isActive': true,
            }, SetOptions(merge: true));

        print('FCM token saved successfully: ${token.substring(0, 20)}...');
      } else {
        print('Driver document not found for email: ${user.email}');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Delete token when user logs out
  Future<void> deleteToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final driverQuery = await _firestore
          .collection('drivers')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (driverQuery.docs.isNotEmpty) {
        final driverDocId = driverQuery.docs.first.id;

        // Get current token
        String? token = await _messaging.getToken();
        if (token != null) {
          // Delete token from Firestore
          await _firestore
              .collection('drivers')
              .doc(driverDocId)
              .collection('tokens')
              .doc(token)
              .delete();
        }

        // Delete FCM token
        await _messaging.deleteToken();
        print('FCM token deleted');
      }
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }

  // Subscribe to topics (optional - for broadcast messages)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
