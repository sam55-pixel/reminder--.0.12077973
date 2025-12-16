import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_reminder/models/location.dart';
import 'package:smart_reminder/models/reminder.dart';
import 'package:smart_reminder/services/context_service.dart';
import 'package:smart_reminder/services/location_service.dart';
import 'package:smart_reminder/services/notification_service.dart';
import 'package:smart_reminder/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive - this MUST be done for all models.
  await Hive.initFlutter();
  Hive.registerAdapter(ReminderAdapter());
  Hive.registerAdapter(LocationAdapter());
  await Hive.openBox<Reminder>('reminders');
  await Hive.openBox<Location>('locations');
  await Hive.openBox('context');

  // Initialize services that DO NOT require UI.
  await NotificationService.init();
  await ContextService.startListening();
  await LocationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
