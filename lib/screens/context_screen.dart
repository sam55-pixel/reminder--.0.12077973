import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ContextService {
  static String currentActivity = "UNKNOWN";
  static String currentLocationText = "Getting location...";

  // This runs in background (call from main.dart)
  static void startListening() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      // Update location text (you can use reverse geocoding later)
      currentLocationText = "Lat: ${position.latitude.toStringAsFixed(4)}, "
                            "Lng: ${position.longitude.toStringAsFixed(4)}";

      // DETECT ACTIVITY (this is the magic)
      final speed = position.speed; // meters per second

      if (speed < 0.5) {
        currentActivity = "STILL"; // sitting, standing, chilling
      } else if (speed < 2.5) {
        currentActivity = "WALKING"; // normal walk
      } else if (speed < 10) {
        currentActivity = "RUNNING / CYCLING"; // too fast!
      } else {
        currentActivity = "IN VEHICLE"; // car, bus, okada
      }

      // Save to Hive so UI can show it live
      final box = Hive.box('context');
      await box.put('activity', currentActivity);
      await box.put('location', currentLocationText);
    });
  }

  
  static bool shouldDeliverReminderNow() {
    return currentActivity == "STILL" || currentActivity == "WALKING";
  }

  static String getCurrentActivity() => currentActivity;
  static String getCurrentLocation() => currentLocationText;
}