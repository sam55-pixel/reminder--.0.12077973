import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/reminder.dart';
import 'notification_service.dart';

class GeofenceService {
  static const double _radius = 120; // meters

  static Future<void> registerAll() async {
    final box = Hive.box<Reminder>('reminders');
    for (final reminder in box.values.where((r) =>
        r.active &&
        r.triggerType == "Location" &&
        r.lat != null &&
        r.lng != null)) {
      _monitorLocation(reminder);
    }
  }

  static Future<void> addNewLocationReminder(Reminder reminder) async {
    if (reminder.lat != null && reminder.lng != null) {
      _monitorLocation(reminder);
    }
  }

  static void _monitorLocation(Reminder reminder) {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((Position position) async {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        reminder.lat!,
        reminder.lng!,
      );

      // Only trigger if close AND reminder still active
      if (distance <= _radius && reminder.active) {
        final int reminderId = reminder.key is int
            ? reminder.key as int
            : int.parse(reminder.key.toString());

        

        await NotificationService.showLoudAlarm(
  id: reminderId,
  title: "YOU HAVE ARRIVED!",
  body: reminder.title,
);

        // Mark as delivered (only once)
        reminder.active = false;
        await reminder.save();
      }
    });
  }
}