import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_reminder/services/context_service.dart';
import 'package:smart_reminder/services/permission_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  log("Notification tapped. Applying context-aware auto-snooze/dismiss logic.");

  final notifications = FlutterLocalNotificationsPlugin();
  tz_data.initializeTimeZones();

  if (notificationResponse.payload == null) {
    log("Error: Payload is null.");
    return;
  }

  final parts = notificationResponse.payload!.split('|');
  if (parts.length < 3) {
      log("Error: Invalid payload format.");
      return;
  }
  final id = int.parse(parts[0]);
  final title = parts[1];
  final body = parts[2];

  // Always cancel the original notification that was tapped.
  await notifications.cancel(id);
  log("Canceled original notification #$id.");

  // Get current user activity.
  final activity = ContextService.getCurrentActivity();
  log("Current activity: $activity");

  // If user is moving, auto-snooze. Otherwise, dismiss.
  if (activity == 'STILL') {
    log("ACTION: User is still. Dismissing reminder #$id.");
    // No further action needed, the notification is already cancelled.
  } else {
    log("ACTION: User is moving ($activity). Snoozing reminder #$id for 5 minutes.");
    
    final androidDetails = AndroidNotificationDetails(
      'stoic_alarm_channel',
      'Stoic Oracle Alarms',
      channelDescription: 'Critical reminders that bypass Do Not Disturb',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: false,
      ongoing: false,
      autoCancel: true,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      sound: const RawResourceAndroidNotificationSound('alarm'),
      additionalFlags: Int32List.fromList([4]),
      // Buttons are removed.
    );

    try {
      await notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 5)),
        NotificationDetails(android: androidDetails),
        payload: notificationResponse.payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      log("SUCCESS: Rescheduled snoozed reminder #$id");
    } catch (e, s) {
      log("Error rescheduling notification: $e", stackTrace: s);
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'stoic_alarm_channel',
    'Stoic Oracle Alarms',
    description: 'Critical reminders that bypass Do Not Disturb',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: const RawResourceAndroidNotificationSound('alarm'),
  );

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      const InitializationSettings(android: androidInit),
      // Use the new context-aware handler for both foreground and background taps
      onDidReceiveNotificationResponse: notificationTapBackground,
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
    final payload = '$id|$title|$body';

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: false,
      ongoing: false,
      autoCancel: true,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      // Buttons are removed.
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
      log("Error scheduling via NotificationService: $e");
    }
  }

  static Future<void> showLoudAlarm({
    required int id,
    required String title,
    required String body,
  }) async {
    if (ContextService.shouldDeliverReminderNow()) {
      await scheduleExactAlarm(id: id, title: title, body: body, when: DateTime.now().add(const Duration(seconds: 2)));
    }
  }

  static Future<void> cancel(int id) async => await _notifications.cancel(id);
  static Future<void> cancelAll() async => await _notifications.cancelAll();
}
