import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'models/reminder.dart';
import 'models/location.dart';
import 'services/notification_service.dart';
import 'services/geofence_service.dart';
import 'screens/context_screen.dart';        
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(StoredLocationAdapter());
  await Hive.openBox<Reminder>('reminders');
  await Hive.openBox<StoredLocation>('locations');
  await Hive.openBox('settings');
  await Hive.openBox('context'); // ← Optional: for saving activity history

  // 2. Init Timezone + Notifications
  tz.initializeTimeZones();
  await NotificationService.init();

  if (!kIsWeb) {
    // 3. Re-register TIME reminders on restart
    final reminderBox = Hive.box<Reminder>('reminders');
    final now = DateTime.now();
    for (final reminder in reminderBox.values.where((r) => 
    r.active && 
    r.scheduledTime != null && 
    r.scheduledTime!.isAfter(now))) {

  final int reminderId = reminder.key is int 
      ? reminder.key as int 
      : int.parse(reminder.key.toString());

  await NotificationService.scheduleExactAlarm(
    id: reminderId,
    title: "REMINDER!",
    body: reminder.title,
    when: reminder.scheduledTime!,
  );
}

    // 4. Re-register LOCATION reminders (geofencing)
    await GeofenceService.registerAll();

    // THE MOST IMPORTANT LINE — THIS ACTIVATES THE STOIC BRAIN
    ContextService.startListening(); // ← ADD THIS LINE ONLY
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
        fontFamily: 'Poppins', // optional: add Google Font for premium feel
      ),
      home: const HomeScreen(),
    );
  }
}