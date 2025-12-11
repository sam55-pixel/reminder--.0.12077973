import 'dart:async';
import 'dart:developer';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_reminder/models/location.dart';
import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/notification_service.dart';

class ContextService {
  static String currentActivity = "UNKNOWN";
  static String currentLocationText = "Getting location...";

  static StreamSubscription<Position>? _positionSubscription;
  static StreamSubscription<ActivityEvent>? _activitySubscription;

  static Future<void> startListening() async {
    final contextBox = await Hive.openBox('context');
    final remindersBox = Hive.box<Reminder>('reminders');
    final locationsBox = Hive.box<Location>('locations');

    // Start listening to activity recognition
    _activitySubscription?.cancel();
    final activityRecognition = ActivityRecognition();
    _activitySubscription = activityRecognition.activityStream().listen((ActivityEvent event) {
      log("New activity event: ${event.type.name}");
      currentActivity = event.type.name;
      contextBox.put('activity', currentActivity);
    });

    // Start listening to location updates
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) async {
        currentLocationText =
            "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";

        const double radius = 120; // Radius in meters
        if (remindersBox.isEmpty) return;

        for (var reminder in remindersBox.values) {
          if (reminder.isLocationBased && reminder.active && !reminder.wasNotified) {
            final location = locationsBox.get(reminder.locationKey);

            if (location != null) {
              final distance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                location.latitude,
                location.longitude,
              );

              final bool inRange = distance <= radius;

              if (inRange && shouldDeliverReminderNow()) {
                log("DELIVERING REMINDER: ${reminder.title}");

                await NotificationService.scheduleExactAlarm(
                  id: reminder.key as int,
                  title: reminder.title,
                  body: "You are at ${location.name}!",
                  when: DateTime.now().add(const Duration(seconds: 1)),
                );

                reminder.wasNotified = true;
                await reminder.save();
              }
            }
          }
        }
      },
      onError: (error) {
        log("Location stream error: $error");
        currentLocationText = "Location error";
      },
    );
  }

  static bool shouldDeliverReminderNow() {
    return currentActivity == "STILL" || currentActivity == "WALKING";
  }

  static Future<String> getCurrentActivity() async {
    final box = await Hive.openBox('context');
    return box.get('activity', defaultValue: 'UNKNOWN');
  }

  static String getCurrentLocation() => currentLocationText;

  static void dispose() {
    _positionSubscription?.cancel();
    _activitySubscription?.cancel();
  }
}
