import '../../services/geofence_service.dart';
import '../../services/context_service.dart';

class ServicesInitializer {
  // This method is now a Future and no longer requests permissions.
  static Future<void> initialize() async {
    // Re-register LOCATION reminders (geofencing)
    await GeofenceService.registerAll();

    // THE MOST IMPORTANT LINE — THIS ACTIVATES THE STOIC BRAIN
    ContextService.startListening();
  }
}
