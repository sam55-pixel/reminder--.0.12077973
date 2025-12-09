import '../../services/permission_service.dart';
import '../../services/geofence_service.dart';
import '../../services/context_service.dart';

class ServicesInitializer {
  static void initialize() async {
    // 0. Request permissions
    await PermissionService.requestNotificationPermission();
    await PermissionService.requestLocationPermission();

    // 3. Re-register LOCATION reminders (geofencing)
    await GeofenceService.registerAll();

    // 4. THE MOST IMPORTANT LINE — THIS ACTIVATES THE STOIC BRAIN
    ContextService.startListening();
  }
}
