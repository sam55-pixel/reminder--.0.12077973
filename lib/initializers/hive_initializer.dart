import 'package:hive_flutter/hive_flutter.dart';

import '../models/location.dart';
import '../models/reminder.dart';

class HiveInitializer {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ReminderAdapter());
    Hive.registerAdapter(StoredLocationAdapter());
    await Hive.openBox<Reminder>('reminders');
    await Hive.openBox<StoredLocation>('locations');
    await Hive.openBox('settings');
    await Hive.openBox('context');
  }
}
