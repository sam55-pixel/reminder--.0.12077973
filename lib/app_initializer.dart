import 'initializers/hive_initializer.dart';
import 'initializers/notification_initializer.dart';
import 'initializers/services_initializer.dart';
import 'initializers/timezone_initializer.dart';

class AppInitializer {
  static Future<void> initialize() async {
    // Lightweight initialization
    await HiveInitializer.initialize();
    TimezoneInitializer.initialize();
    await NotificationInitializer.initialize();

    // Heavy lifting after the app has started
    ServicesInitializer.initialize();
  }
}
