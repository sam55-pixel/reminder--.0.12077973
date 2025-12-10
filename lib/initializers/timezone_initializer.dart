import 'package:timezone/data/latest_all.dart' as tz;

class TimezoneInitializer {
  static void initialize() {
    tz.initializeTimeZones();
  }
}
