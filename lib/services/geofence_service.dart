import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:smart_reminder/models/location.dart';
import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/location_service.dart';
import 'package:smart_reminder/services/notification_service.dart';

class GeofenceService {
  static StreamSubscription<Position>? _positionStream;

  static void start() {
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Trigger check every 100 meters
      ),
    ).listen((position) {
      _checkGeofences(position);
    });
  }

  static void stop() {
    _positionStream?.cancel();
  }

  static void _checkGeofences(Position position) {
    final reminderBox = Hive.box<Reminder>('reminders');
    // Get active, location-based reminders that haven't been notified yet
    final reminders = reminderBox.values.where((r) => r.active && r.isLocationBased && !r.wasNotified);
    final locations = LocationService.getSavedLocations();

    for (final reminder in reminders) {
      if (reminder.locationKey != null) {
        // Find the location associated with the reminder
        final location = locations.firstWhere((loc) => loc.key == reminder.locationKey, orElse: () => Location(name: '', latitude: 0, longitude: 0));

        // Check if a valid location was found
        if (location.name.isNotEmpty) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            location.latitude,
            location.longitude,
          );

          // If user is within the 100-meter radius
          if (distance <= 100) {
            // Show notification and mark the reminder as notified
            NotificationService.showLocationReminder(
              id: reminder.key,
              title: reminder.title,
              body: 'You have arrived at ${location.name}',
            );
            reminder.wasNotified = true;
            reminder.save();
          }
        }
      }
    }
  }
}
