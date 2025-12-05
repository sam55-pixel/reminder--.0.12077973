import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

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
    
  );

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) async {
        // Handle SNOOZE or DISMISS
        if (response.actionId == 'snooze' && response.payload != null) {
          final parts = response.payload!.split('|');
          final id = int.parse(parts[0]);
          final title = parts[1];
          final body = parts[2];
          final newTime = DateTime.now().add(const Duration(minutes: 5));

          await scheduleExactAlarm(
            id: id,
            title: title,
            body: body,
            when: newTime,
          );
        }
      },
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
    final androidDetails = AndroidNotificationDetails(
      'stoic_alarm_channel',
      'Stoic Oracle Alarms',
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
        AndroidNotificationAction('snooze', 'Snooze 5 min'),
      ],
    );

    final payload = '$id|$title|$body';

    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  
  static Future<void> showLoudAlarm({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'stoic_alarm_channel',
      'Stoic Oracle Alarms',
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
        AndroidNotificationAction('snooze', 'Snooze 5 min'),
      ],
    );

    final payload = '$id|$title|$body';

    await _notifications.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<void> cancel(int id) async => await _notifications.cancel(id);
  static Future<void> cancelAll() async => await _notifications.cancelAll();
}