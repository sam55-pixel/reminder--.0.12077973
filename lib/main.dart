import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'models/reminder.dart';
import 'models/location.dart';
import 'services/notification_service.dart';
import 'services/geofence_service.dart';
import 'services/context_service.dart'; // CORRECTED IMPORT
import 'screens/home_screen.dart';
import 'services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Request permissions
  await PermissionService.requestNotificationPermission();
  await PermissionService.requestLocationPermission();

  // 1. Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(StoredLocationAdapter());
  await Hive.openBox<Reminder>('reminders');
  await Hive.openBox<StoredLocation>('locations');
  await Hive.openBox('settings');
  await Hive.openBox('context');

  // 2. Init Timezone + Notifications
  tz.initializeTimeZones();
  await NotificationService.init();

  if (!kIsWeb) {
    // 3. Re-register LOCATION reminders (geofencing)
    await GeofenceService.registerAll();

    // 4. THE MOST IMPORTANT LINE — THIS ACTIVATES THE STOIC BRAIN
    ContextService.startListening(); // This will now be correctly defined
  }

  runApp(const ReminderApp());
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stoic Oracle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const HomeScreen(),
    );
  }
}
