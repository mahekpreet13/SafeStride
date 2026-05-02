import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

/// Service responsible for managing local notifications.
/// Handles initialization, permission requests, and notification display.
class NotificationService {
  static const String _dangerZoneChannelId = 'danger_zone_channel_v1';
  static const String _dangerZoneChannelName = 'Gefahrenzonen Warnungen';
  static const String _dangerZoneChannelDescription =
      'Benachrichtigungen für Gefahrenzonen und Sicherheitswarnungen';

  FlutterLocalNotificationsPlugin? _notifications;
  Function(NotificationResponse)? _onNotificationTap;

  /// Initialize the notification service with platform-specific settings.
  Future<bool> initialize({
    Function(NotificationResponse)? onNotificationTap,
    Function(NotificationResponse)? onBackgroundNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;
    _notifications = FlutterLocalNotificationsPlugin();

    try {
      // Request notification permissions for Android 13+
      final androidImplementation = _notifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      bool? permissionGranted;
      if (androidImplementation != null) {
        permissionGranted =
            await androidImplementation.requestNotificationsPermission();
        debugPrint('Android notification permission granted: $permissionGranted');
      }

      // Initialize notification settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _notifications!.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationTap,
      );

      // Create notification channel for Android
      await _createDangerZoneChannel();

      return permissionGranted ?? true;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
      return false;
    }
  }

  /// Creates the danger zone notification channel for Android.
  Future<void> _createDangerZoneChannel() async {
    final androidImplementation = _notifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dangerZoneChannelId,
        _dangerZoneChannelName,
        description: _dangerZoneChannelDescription,
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );
    debugPrint('Danger zone notification channel created');
  }

  /// Shows a danger zone warning notification.
  Future<void> showDangerZoneAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (_notifications == null) {
      debugPrint('Notifications not initialized');
      return;
    }

    try {
      await _notifications!.show(
        0, // Notification ID
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dangerZoneChannelId,
            _dangerZoneChannelName,
            channelDescription: _dangerZoneChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            playSound: false,
            enableVibration: false,
            ticker: 'Gefahrenzone',
          ),
          iOS: DarwinNotificationDetails(
            presentSound: false,
            presentAlert: true,
            presentBadge: true,
          ),
        ),
        payload: payload ?? 'danger_zone_alert_${DateTime.now().millisecondsSinceEpoch}',
      );
      debugPrint('Danger zone notification sent');
    } catch (e) {
      debugPrint('Failed to show danger zone notification: $e');
      rethrow;
    }
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    await _notifications?.cancelAll();
  }

  /// Cancels a specific notification by ID.
  Future<void> cancel(int id) async {
    await _notifications?.cancel(id);
  }
}
