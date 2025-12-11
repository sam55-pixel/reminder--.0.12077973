import 'package:hive_flutter/hive_flutter.dart';

import '../models/location.dart';
import '../models/reminder.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register the adapters for the models
    Hive.registerAdapter(ReminderAdapter());
    Hive.registerAdapter(LocationAdapter());

    // Open the Hive boxes
    await Hive.openBox<Reminder>('reminders');
    await Hive.openBox<Location>('locations'); // Use the new Location model
    await Hive.openBox('settings');
    await Hive.openBox('context');
  }
}
