import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final supabase = Supabase.instance.client;

  /// Initialize Firebase and Local Notifications
  static Future<void> init() async {
    // 1. Request Permissions (iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');
    }

    // 2. Local Notifications Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click
        debugPrint('🔔 Notification clicked: ${details.payload}');
      },
    );

    // 3. Foreground Listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground Message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 4. Background/Terminated Click Listeners
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '🔔 App opened from notification: ${message.notification?.title}',
      );
    });

    // 5. Get Initial Token
    await _saveToken();

    // 6. Token Refresh Listener
    _fcm.onTokenRefresh.listen((token) => _saveToken(token));

    // 7. Setup Interacted Message (Terminated State)
    await setupInteractedMessage();
  }

  /// Handle interaction when app is opened from notification
  static Future<void> setupInteractedMessage() async {
    // Get distinct message if the app was terminated
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Also handle background -> foreground transition
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  /// Handle navigation logic based on message
  static void _handleMessage(RemoteMessage message) {
    debugPrint('🔄 Handling notification interaction: ${message.data}');
    // Example: Navigator.pushNamed(context, '/chat', arguments: message.data);
  }

  /// Get and save FCM Token to Supabase
  static Future<void> _saveToken([String? token]) async {
    try {
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken != null) {
        debugPrint('🔑 FCM Token: $fcmToken');

        final userId = supabase.auth.currentUser?.id;
        if (userId != null) {
          final platform = Platform.isAndroid ? 'android' : 'ios';

          await supabase
              .from('profiles')
              .update({'fcm_token': fcmToken, 'fcm_platform': platform})
              .eq('id', userId);

          debugPrint('✅ FCM Token registered with Supabase');
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Show Local Notification when in foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'aroggyapath_notifications',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: message.data.toString(),
    );
  }

  // ========================================
  // Existing REST API methods
  // ========================================

  /// Fetch all notifications from Supabase
  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count with Supabase
  static Future<int> getUnreadCount() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark a single notification as read with Supabase
  static Future<bool> markAsRead(String id) async {
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('❌ Error marking as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read with Supabase
  static Future<bool> markAllAsRead() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
      return false;
    }
  }

  /// Delete a notification with Supabase
  static Future<bool> deleteNotification(String id) async {
    try {
      await supabase.from('notifications').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }
}
