// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/reminder.dart';
import 'reminders_screen.dart';
import 'create_reminder_screen.dart';
import 'insights_screen.dart';
import '../screens/settings_screen.dart';
import 'map_context_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _locationText = "Fetching location...";
  String _activity = "Detecting activity...";

  final TextEditingController _searchController = TextEditingController();
  List<Reminder> _reminders = [];
  List<Reminder> _filtered = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _startLocationAndActivityDetection();
    _searchController.addListener(_filterReminders);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadReminders() {
    final box = Hive.box<Reminder>('reminders');
    setState(() {
      _reminders = box.values.toList();
      _filtered = List.from(_reminders);
    });
  }

  void _startLocationAndActivityDetection() {
    // LOCATION
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) return;
      setState(() {
        _locationText = "Lat: ${position.latitude.toStringAsFixed(4)}, "
                        "Lng: ${position.longitude.toStringAsFixed(4)}";
      });
    });

    // ACTIVITY DETECTION (from sensors)
    _accelSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen((event) {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      String detected;

      if (magnitude < 10.2) {
        detected = "STILL";
      } else if (magnitude < 15.0) {
        detected = "WALKING";
      } else {
        detected = "RUNNING / IN VEHICLE";
      }

      if (!mounted) return;
      setState(() => _activity = detected);
    });
  }

  void _filterReminders() {
  final query = _searchController.text.toLowerCase().trim();
  
  setState(() {
    _filtered = _reminders.where((r) =>
        r.title.toLowerCase().contains(query) ||
        (r.locationName?.toLowerCase().contains(query) ?? false)
    ).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 1. Reminders
          RemindersScreen(
            reminders: _filtered,
            searchController: _searchController,
          ),

          // 2. Live Context (NOW WORKS!)
          MapContextScreen(
            locationText: _locationText,
            currentActivity: _activity,
          ),

          // 3. Insights
          const InsightsScreen(),

          // 4. Settings
          const SettingsScreen(),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReminderScreen()),
          );
          if (result == true || mounted) _loadReminders();
        },
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'Stoic AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}