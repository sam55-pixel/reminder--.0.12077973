import 'package:permission_handler/permission_handler.dart';

class PermissionService {

  static Future<void> requestLocationPermission() async {
    // Request multiple permissions at once to avoid race conditions.
    await [Permission.location, Permission.locationAlways].request();
  }

  static Future<void> requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }
}
