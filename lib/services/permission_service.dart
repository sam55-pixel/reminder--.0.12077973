import 'package:permission_handler/permission_handler.dart';

class PermissionService {

  static Future<void> requestInitialPermissions() async {
    // Request all permissions needed at startup in a single call.
    await [Permission.location, 
           Permission.locationAlways, 
           Permission.notification, 
           Permission.activityRecognition,
           Permission.scheduleExactAlarm].request();
  }

  static Future<void> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // The following methods are kept for now in case they are needed for 
  // more granular, context-specific requests later, but the initial startup
  // should use requestInitialPermissions.

  static Future<void> requestLocationPermission() async {
    await [Permission.location, Permission.locationAlways].request();
  }

  static Future<void> requestActivityRecognitionPermission() async {
    final status = await Permission.activityRecognition.status;
    if (status.isDenied) {
      await Permission.activityRecognition.request();
    }
  }

  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }
}
