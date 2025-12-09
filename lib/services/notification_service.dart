import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/permission_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // handle action
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
    final box = await Hive.openBox<Reminder>('reminders');

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (response) async {
        if (response.payload == null) {
          return;
        }

        final parts = response.payload!.split('|');
        final id = int.parse(parts[0]);
        final reminder = box.get(id);

        if (reminder == null) {
          return;
        }

        if (response.actionId == 'snooze') {
          reminder.scheduledTime = DateTime.now().add(const Duration(minutes: 5));
          reminder.active = true;
          await reminder.save();
        } else if (response.actionId == 'dismiss') {
          await box.delete(id);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);

    // Handle payloads from MainActivity
    const MethodChannel('notification_payload').setMethodCallHandler((call) async {
      if (call.method == 'notification_payload') {
        final payload = call.arguments as String;
        final parts = payload.split('|');
        final id = int.parse(parts[0]);
        final box = await Hive.openBox<Reminder>('reminders');
        final reminder = box.get(id);

        if (reminder != null) {
          await box.delete(id);
        }
      }
    });
  }

  static Future<void> scheduleExactAlarm(
      {required int id,
      required String title,
      required String body,
      required DateTime when}) async {
    // Intentionally blank.
  }

  static Future<void> showLoudAlarm(
      {required int id, required String title, required String body}) async {
    await PermissionService.requestExactAlarmPermission();

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
      sound: const RawResourceAndroidNotificationSound('alarm'),
      additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT
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
