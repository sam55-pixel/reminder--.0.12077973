import 'initializers/hive_initializer.dart';
import 'initializers/notification_initializer.dart';
import 'initializers/permission_initializer.dart';
import 'initializers/services_initializer.dart';
import 'initializers/timezone_initializer.dart';

class AppInitializer {
  static Future<void> initialize() async {
    // Request all permissions first to avoid race conditions
    await PermissionInitializer.initialize();

    // Proceed with other initializations
    await HiveInitializer.initialize();
    TimezoneInitializer.initialize();
    await NotificationInitializer.initialize();

    // Finally, initialize the location and context services
    await ServicesInitializer.initialize();
  }
}
