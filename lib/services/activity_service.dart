import 'package:sensors_plus/sensors_plus.dart';
import 'package:hive/hive.dart';
import 'dart:async';  // For timeout

class ActivityService {
  static String detectActivity(AccelerometerEvent event) {
    final magnitude = event.x.abs() + event.y.abs() + event.z.abs();

    if (magnitude < 9.8) return "STILL";
    if (magnitude < 22.0) return "WALKING";
    return "RUNNING / IN VEHICLE";
  }

  /// Runs in background (Workmanager) — keeps Stoic AI learning 24/7
  static Future<void> updateContextLearningInBackground() async {
    try {
      final event = await accelerometerEventStream(
        samplingPeriod: SensorInterval.normalInterval,
      ).first.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          // 4 ARGUMENTS REQUIRED: x, y, z, timestamp
          return AccelerometerEvent(
            0.0,  // x
            0.0,  // y
            9.8,  // z (gravity)
            DateTime.now(),  // timestamp
          );
        },
      );

      final currentActivity = detectActivity(event);
      await Hive.box('settings').put('lastKnownActivity', currentActivity);
    } catch (e) {
      // Fallback for emulators or sensor errors
      await Hive.box('settings').put('lastKnownActivity', 'STILL');
    }
  }
}