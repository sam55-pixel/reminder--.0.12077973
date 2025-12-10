import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/notification_service.dart';

class ContextService {
  static String currentActivity = "UNKNOWN";
  static String currentLocationText = "Getting location...";
  static Timer? _timer;

  static void startListening() {
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

    _timer?.cancel();
    // The timer now only checks for time-based reminders.
    _timer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _checkTimeBasedReminders();
    });
  }

  static void _checkTimeBasedReminders() {
    final now = DateTime.now();
    final box = Hive.box<Reminder>('reminders');

    for (final reminder in box.values) {
      // Check if reminder is due and hasn't been notified yet.
      if (reminder.active &&
          !reminder.wasNotified &&
          reminder.scheduledTime != null &&
          now.isAfter(reminder.scheduledTime!)) {
        // Check if the user is in a state to receive the notification.
        if (shouldDeliverReminderNow()) {
          final int reminderId = reminder.key as int;

          NotificationService.showLoudAlarm(
            id: reminderId,
            title: "TIME'S UP!",
            body: reminder.title,
          );

          // Mark as notified to prevent re-triggering.
          // The user can manually delete it from the app list later.
          reminder.wasNotified = true;
          reminder.save();
        }
      }
    }
  }

  static bool shouldDeliverReminderNow() {
    // A user is considered available if they are not moving too fast.
    return currentActivity == "STILL" || currentActivity == "WALKING";
  }

  static String getCurrentActivity() => currentActivity;
  static String getCurrentLocation() => currentLocationText;
}
