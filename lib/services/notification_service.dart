import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/context_service.dart';
import 'package:smart_reminder/services/permission_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  log("Notification action received: ${notificationResponse.actionId}");

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(ReminderAdapter().typeId)) {
    Hive.registerAdapter(ReminderAdapter());
  }

  if (notificationResponse.payload == null) return;

  final id = int.tryParse(notificationResponse.payload!);
  if (id == null) return;

  await NotificationService.cancel(id);

  final box = await Hive.openBox<Reminder>('reminders');
  final reminder = box.get(id);

  if (reminder != null) {
    switch (notificationResponse.actionId) {
      case 'ignore':
        final currentContext = await ContextService.getCurrentActivity();
        // The .name property provides the String representation of the enum (e.g., 'WALKING')
        reminder.ignored(currentContext.name);
        await reminder.save();
        log('Reminder #${reminder.key} ignored in context: ${currentContext.name}');
        break;
      case 'snooze_10':
        log('Snoozing reminder #${reminder.key} for 10 minutes.');
        await NotificationService.scheduleExactAlarm(
          id: id,
          title: reminder.title,
          body: "Snoozed for 10 minutes",
          when: DateTime.now().add(const Duration(minutes: 10)),
        );
        break;
      case 'task_done':
      default:
        log('Reminder #${reminder.key} marked as done.');
        reminder.wasNotified = true;
        reminder.active = false;
        await reminder.save();
        break;
    }
  }
  await box.close();
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'smart_reminder_alarms_v2',
    'Smart Reminder Alarms',
    description: 'Channel for important, insistent reminder alarms.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
  );

  static final AndroidNotificationChannel _locationAlarmChannel =
      AndroidNotificationChannel(
    'location_alarms_v2',
    'Location Alarms',
    description: 'Channel for high-priority, insistent location-based alarms.',
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
      onDidReceiveNotificationResponse: notificationTapBackground,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_locationAlarmChannel);
  }

  static Future<void> showLocationReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    await PermissionService.requestNotificationPermission();
    final payload = id.toString();
    final androidDetails = AndroidNotificationDetails(
      _locationAlarmChannel.id,
      _locationAlarmChannel.name,
      channelDescription: _locationAlarmChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      ongoing: false,
      autoCancel: true,
      sound: _locationAlarmChannel.sound,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      additionalFlags: Int32List.fromList([4]),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('task_done', 'Task Done'),
        const AndroidNotificationAction('snooze_10', 'Snooze 10m'),
        const AndroidNotificationAction('ignore', 'Ignore'),
      ],
    );
    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
      log("SUCCESS: LOCATION ALARM SHOWN: id=$id");
    } catch (e, s) {
      log("Error showing location notification: $e", stackTrace: s);
    }
  }

  static Future<void> scheduleExactAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    await PermissionService.requestNotificationPermission();
    await PermissionService.requestExactAlarmPermission();
    final payload = id.toString();
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: false,
      ongoing: false,
      autoCancel: true,
      sound: _channel.sound,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      additionalFlags: Int32List.fromList([4]),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('task_done', 'Task Done'),
        const AndroidNotificationAction('ignore', 'Ignore'),
      ],
    );
    var tzWhen = tz.TZDateTime.from(when, tz.local);
    final tzNow = tz.TZDateTime.now(tz.local);
    if (tzWhen.isBefore(tzNow)) {
      tzWhen = tzNow.add(const Duration(seconds: 2));
    }
    log("SCHEDULING ALARM: id=$id, title='$title', when=$tzWhen");
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
      log("SUCCESS: ALARM SCHEDULED: id=$id");
    } catch (e, s) {
      log("Error scheduling notification: $e", stackTrace: s);
    }
  }

  static Future<void> cancel(int id) async => await _notifications.cancel(id);
  static Future<void> cancelAll() async => await _notifications.cancelAll();
}
