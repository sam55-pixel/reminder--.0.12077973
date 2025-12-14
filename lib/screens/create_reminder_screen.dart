import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_reminder/models/location.dart';
import 'package:smart_reminder/services/location_service.dart';

import '../models/reminder.dart';
import '../services/notification_service.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  DateTime? _selectedTime;
  dynamic _selectedLocationKey;

  String _triggerType = "Location"; // Default, will be adapted

  @override
  void initState() {
    super.initState();
    _loadAdaptedTrigger();
  }

  Future<void> _loadAdaptedTrigger() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _triggerType = prefs.getString('lastTriggerType') ?? "Location";
    });
  }

  Future<void> _saveAdaptedTrigger() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastTriggerType', _triggerType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Reminder"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 28),
            onPressed: _createReminder,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTitleField(),
          const SizedBox(height: 20),
          _buildTriggerTypeSelector(),
          const SizedBox(height: 20),
          if (_triggerType == 'Time') _buildTimePicker(),
          if (_triggerType == 'Location') _buildLocationPicker(),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: 'What do you want to be reminded of?',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.title),
      ),
    );
  }

  Widget _buildTriggerTypeSelector() {
    return SegmentedButton<String>(
      style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12)),
      segments: const [
        ButtonSegment(
            value: 'Time', label: Text('Time'), icon: Icon(Icons.access_time)),
        ButtonSegment(
            value: 'Location',
            label: Text('Location'),
            icon: Icon(Icons.location_on)),
      ],
      selected: {_triggerType},
      onSelectionChanged: (newSelection) {
        setState(() {
          _triggerType = newSelection.first;
        });
      },
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.grey)),
      leading: const Icon(Icons.calendar_today),
      title: const Text("Choose a time"),
      subtitle: Text(_selectedTime != null
          ? DateFormat('h:mm a').format(_selectedTime!)
          : "Not set"),
      onTap: () async {
        final time = await showTimePicker(
            context: context, initialTime: TimeOfDay.now());
        if (time != null) {
          final now = DateTime.now();
          setState(() {
            _selectedTime = DateTime(
                now.year, now.month, now.day, time.hour, time.minute);
          });
        }
      },
    );
  }

  Widget _buildLocationPicker() {
    final locations = LocationService.getSavedLocations();

    return DropdownButtonFormField<dynamic>(
      initialValue: _selectedLocationKey,
      decoration: InputDecoration(
        labelText: 'Select a Location',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.map_outlined),
      ),
      items: locations.whereType<Location>().map((location) {
        return DropdownMenuItem<dynamic>(
          value: location.key,
          child: Text(location.name),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedLocationKey = value;
        });
      },
    );
  }

  Future<void> _createReminder() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the reminder.')),
      );
      return;
    }

    final box = Hive.box<Reminder>('reminders');
    final newReminder = Reminder(
      title: _titleController.text,
      created: DateTime.now(),
      triggerType: _triggerType,
      locationKey: _selectedLocationKey,
      scheduledTime: _selectedTime,
      active: true,
    );

    final key = await box.add(newReminder);

    if (newReminder.isTimeBased && newReminder.scheduledTime != null) {
      await NotificationService.scheduleExactAlarm(
        id: key,
        title: newReminder.title,
        body: "It's time!",
        when: newReminder.scheduledTime!,
      );
    }

    await _saveAdaptedTrigger();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
