import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/permission_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  _handleNotificationResponse(notificationResponse);
}

Future<void> _handleNotificationResponse(NotificationResponse response) async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(ReminderAdapter().typeId)) {
    Hive.registerAdapter(ReminderAdapter());
  }
  final box = await Hive.openBox<Reminder>('reminders');

  if (response.payload == null) {
    return;
  }

  final parts = response.payload!.split('|');
  final id = int.parse(parts[0]);
  final originalTitle = parts.length > 1 ? parts[1] : 'Reminder';
  final originalBody = parts.length > 2 ? parts[2] : 'Your reminder is due!';

  if (response.actionId == 'snooze') {
    final reminder = box.get(id);
    if (reminder != null) {
      final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
      reminder.scheduledTime = snoozeTime;
      reminder.active = true;
      await reminder.save();
      await NotificationService.scheduleExactAlarm(
        id: reminder.key,
        title: originalTitle,
        body: originalBody,
        when: snoozeTime,
      );
    }
  } else if (response.actionId == 'dismiss') {
    if (box.containsKey(id)) {
      await box.delete(id);
    }
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
    final payload = '$id|$title|$body';

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      autoCancel: false,
      ongoing: true,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      actions: const [
        AndroidNotificationAction('dismiss', 'Dismiss', cancelNotification: true),
        AndroidNotificationAction('snooze', 'Snooze 5 min', cancelNotification: true),
      ],
      sound: const RawResourceAndroidNotificationSound('alarm'),
      additionalFlags: Int32List.fromList([4]),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(android: androidDetails),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showLoudAlarm({
    required int id,
    required String title,
    required String body,
  }) async {
    await scheduleExactAlarm(id: id, title: title, body: body, when: DateTime.now());
  }

  static Future<void> cancel(int id) async => await _notifications.cancel(id);
  static Future<void> cancelAll() async => await _notifications.cancelAll();
}
