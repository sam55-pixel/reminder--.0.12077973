import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/notification_service.dart';

class ContextService {
  static String currentActivity = "UNKNOWN";
  static String currentLocationText = "Getting location...";
  static Timer? _timer;

  // This runs in background (call from main.dart)
  static void startListening() {
    // 1. Listen for location changes to determine activity
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      currentLocationText = "Lat: ${position.latitude.toStringAsFixed(4)}, "
          "Lng: ${position.longitude.toStringAsFixed(4)}";

      final speed = position.speed;
      if (speed < 0.5) {
        currentActivity = "STILL";
      } else if (speed < 2.5) {
        currentActivity = "WALKING";
      } else if (speed < 10) {
        currentActivity = "RUNNING / CYCLING";
      } else {
        currentActivity = "IN VEHICLE";
      }

      final box = Hive.box('context');
      await box.put('activity', currentActivity);
      await box.put('location', currentLocationText);
    });

    // 2. Check for time-based reminders every minute
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _checkTimeBasedReminders();
    });
  }

  static void _checkTimeBasedReminders() {
    final now = DateTime.now();
    final box = Hive.box<Reminder>('reminders');

    for (final reminder in box.values) {
      if (reminder.active &&
          reminder.scheduledTime != null &&
          now.isAfter(reminder.scheduledTime!)) {
        if (shouldDeliverReminderNow()) {
          final int reminderId = reminder.key is int
              ? reminder.key as int
              : int.parse(reminder.key.toString());

          NotificationService.showLoudAlarm(
            id: reminderId,
            title: "TIME'S UP!",
            body: reminder.title,
          );

          // Deactivate reminder so it doesn't fire again
          reminder.active = false;
          reminder.save();
        }
      }
    }
  }

  static bool shouldDeliverReminderNow() {
    return currentActivity == "STILL" || currentActivity == "WALKING";
  }

  static String getCurrentActivity() => currentActivity;
  static String getCurrentLocation() => currentLocationText;
}
