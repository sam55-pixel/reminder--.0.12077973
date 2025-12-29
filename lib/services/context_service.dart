import 'dart:async';
import 'dart:developer';
// CORRECTED: Use a prefix to resolve the name conflict with geolocator's ActivityType.
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart' as ar;
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:smart_reminder/models/location.dart';
import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/notification_service.dart';

class ContextService {
  // Use the prefixed constructor
  static final ar.ActivityRecognition activityRecognition = ar.ActivityRecognition();
  // Use the prefixed type
  static StreamSubscription<ar.ActivityEvent>? _activityStreamSubscription;
  static StreamSubscription<Position>? _positionStreamSubscription;
  static Timer? _contextCheckTimer;

  static Future<void> startListening() async {
    await stopListening();
    try {
      _activityStreamSubscription = activityRecognition
          .activityStream(runForegroundService: true)
          .listen(_onActivityUpdate);
      _positionStreamSubscription =
          Geolocator.getPositionStream().listen(_onPositionUpdate);
      _contextCheckTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _evaluateContext(),
      );
      log("Context listeners started.");
    } catch (e) {
      log("Error starting context listeners: $e");
    }
  }

  static Future<void> _onPositionUpdate(Position position) async {
    final box = await Hive.openBox('context');
    await box.put('lastLatitude', position.latitude);
    await box.put('lastLongitude', position.longitude);
    await box.close();
  }

  // Use the prefixed type for the event
  static Future<void> _onActivityUpdate(ar.ActivityEvent activity) async {
    final box = await Hive.openBox('context');
    // The .name property will be the uppercase enum name (e.g., 'WALKING')
    await box.put('lastActivity', activity.type.name);
    await box.close();
  }

  static Future<void> _evaluateContext() async {
    final remindersBox = await Hive.openBox<Reminder>('reminders');
    final locationsBox = await Hive.openBox<Location>('locations');
    try {
      final position = await Geolocator.getCurrentPosition();
      const radius = 100.0; // 100 meters

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

            if (distance <= radius && shouldDeliverReminderNow()) {
              log("DELIVERING REMINDER (from ContextService): ${reminder.title}");
              await NotificationService.showLocationReminder(
                id: reminder.key as int,
                title: reminder.title,
                body: "You are at ${location.name}!",
              );
              reminder.wasNotified = true;
              await reminder.save();
            }
          }
        }
      }
    } finally {
      await remindersBox.close();
      await locationsBox.close();
    }
  }

  static bool shouldDeliverReminderNow() {
    return true;
  }

  // Use the prefixed type for the return value
  static Future<ar.ActivityType> getCurrentActivity() async {
    final box = await Hive.openBox('context');
    // The name should be uppercase, so 'UNKNOWN' is the correct default.
    final activityName = box.get('lastActivity', defaultValue: 'UNKNOWN');
    await box.close();
    // Use the prefixed enum
    return ar.ActivityType.values.firstWhere(
      (e) => e.name == activityName,
      // CORRECTED: Use the prefixed UNKNOWN, which is the correct fallback.
      orElse: () => ar.ActivityType.unknown,
    );
  }

  static Future<void> stopListening() async {
    await _activityStreamSubscription?.cancel();
    await _positionStreamSubscription?.cancel();
    _contextCheckTimer?.cancel();
    log("Context listeners stopped.");
  }
}
