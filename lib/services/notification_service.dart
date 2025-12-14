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

  // Always cancel the notification to remove the sticky alarm
  await NotificationService.cancel(id);

  final box = await Hive.openBox<Reminder>('reminders');
  final reminder = box.get(id);

  if (reminder != null) {
    switch (notificationResponse.actionId) {
      case 'dismiss':
        final currentContext = await ContextService.getCurrentActivity();
        reminder.ignored(currentContext);
        log('Reminder #${reminder.key} ignored in context: $currentContext');
        break;
      case 'snooze_10':
        log('Snoozing reminder #${reminder.key} for 10 minutes.');
        await NotificationService.scheduleExactAlarm(
          id: id,
          title: reminder.title,
          body: "Snoozed for 10 minutes", // General snooze message
          when: DateTime.now().add(const Duration(minutes: 10)),
        );
        // Reminder stays active
        break;
      default: // Default tap action
        reminder.wasNotified = true;
        reminder.active = false;
        break;
    }
    await reminder.save();
  }
  await box.close();
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'smart_reminder_channel',
    'Smart Reminders',
    description: 'Channel for important reminder notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
  );

  // New channel for location-based alarms
  static final AndroidNotificationChannel _locationAlarmChannel =
      AndroidNotificationChannel(
    'location_alarm_channel',
    'Location Alarms',
    description: 'Channel for high-priority location-based alarms.',
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
    await androidPlugin?.createNotificationChannel(
      _locationAlarmChannel,
    ); // Create the new channel
  }

  // New method for showing a persistent, full-screen location alarm
  static Future<void> showLocationReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    // THIS IS THE FIX: Request notification permission before showing.
    await PermissionService.requestNotificationPermission();

    final payload = id.toString();

    final androidDetails = AndroidNotificationDetails(
      _locationAlarmChannel.id,
      _locationAlarmChannel.name,
      channelDescription: _locationAlarmChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // This is key for full-screen alerts
      ongoing: true, // Makes the notification persistent
      autoCancel: false, // User must interact with it
      sound: _locationAlarmChannel.sound,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('snooze_10', 'Snooze 10m'),
        const AndroidNotificationAction('dismiss', 'Dismiss'),
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
    // THIS IS THE FIX: Request both necessary permissions before scheduling.
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
      ongoing: true, // Makes the notification persistent
      autoCancel: false, // User must interact with it
      sound: _channel.sound,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      additionalFlags: Int32List.fromList([4]),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction('dismiss', 'Dismiss'),
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
