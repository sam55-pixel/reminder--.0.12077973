import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {

  static Future<void> requestLocationPermission() async {
    // Request foreground location
    var status = await Permission.location.request();

    // If foreground is granted, you can then request background location.
    if (status.isGranted) {
      await Permission.locationAlways.request();
    }
  }

  static Future<void> requestExactAlarmPermission() async {
    // FIX: Check Android version before requesting permission
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    if (deviceInfo.version.sdkInt >= 31) { // Android 12 (S)
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    }
    
  }

  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }
}
