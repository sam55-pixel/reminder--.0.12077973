import '../../services/context_service.dart';
import '../../services/geofence_service.dart';
import '../../services/location_service.dart';

class ServicesInitializer {
  // This method is now a Future and no longer requests permissions.
  static Future<void> initialize() async {
    // Initialize the Location Service
    await LocationService.init();

    // Start the Geofence Service
    GeofenceService.start();

    // THE MOST IMPORTANT LINE — THIS ACTIVATES THE STOIC BRAIN
    ContextService.startListening();
  }
}
