import 'dart:async';
import 'dart:developer'; // Import the developer library for logging
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_reminder/services/permission_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  _handleNotificationResponse(notificationResponse);
}

// This background handler is now self-contained for snoozing.
Future<void> _handleNotificationResponse(NotificationResponse response) async {
  // GOOD: Added logging for debugging notification actions.
  log("Notification action tapped: ${response.actionId} with payload: ${response.payload}");

  if (response.payload == null || response.actionId == null) {
    return;
  }

  final parts = response.payload!.split('|');
  if (parts.length < 3) return; // Expect id|title|body

  final id = int.parse(parts[0]);
  final title = parts[1];
  final body = parts[2];
  final action = response.actionId;

  if (action == 'snooze') {
    log('Snoozing reminder #$id for 5 minutes.');
    // Re-schedule the alarm directly from the background isolate.
    await NotificationService.scheduleExactAlarm(
      id: id,
      title: title, // Use original title
      body: body,   // and body
      when: DateTime.now().add(const Duration(minutes: 5)),
    );
  } else if (action == 'dismiss') {
    log('Dismissing notification for reminder #$id.');
    // The 'cancelNotification: true' property on the action handles this automatically.
    // No further action is needed. The reminder stays in the DB as 'wasNotified'.
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'stoic_alarm_channel',
    'Stoic Oracle Alarms',
    description: 'Critical reminders that bypass Do Not Disturb',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
  );

  static Future<void> init() async {
    await PermissionService.requestNotificationPermission();
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  static Future<void> scheduleExactAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await PermissionService.requestExactAlarmPermission();
    // Payload now holds everything needed to re-create the alarm.
    final payload = '$id|$title|$body';

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: false,
      ongoing: false,
      // IMPORTANT: AutoCancel is true so notification disappears on tap.
      autoCancel: true,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      actions: const [
        // Both actions now simply cancel the notification. Snooze re-schedules itself.
        AndroidNotificationAction('dismiss', 'Dismiss', cancelNotification: true),
        AndroidNotificationAction('snooze', 'Snooze 5 min', cancelNotification: true),
      ],
      sound: const RawResourceAndroidNotificationSound('alarm'),
      additionalFlags: Int32List.fromList([4]),
    );

    var tzWhen = tz.TZDateTime.from(when, tz.local);
    final tzNow = tz.TZDateTime.now(tz.local);
    if (tzWhen.isBefore(tzNow)) {
      tzWhen = tzNow.add(const Duration(seconds: 5));
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        NotificationDetails(android: androidDetails),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Silently fail on emulator if scheduling is too fast
    }
  }

  static Future<void> showLoudAlarm({
    required int id,
    required String title,
    required String body,
  }) async {
    await scheduleExactAlarm(id: id, title: title, body: body, when: DateTime.now().add(const Duration(seconds: 2)));
  }

  static Future<void> cancel(int id) async => await _notifications.cancel(id);
  static Future<void> cancelAll() async => await _notifications.cancelAll();
}
