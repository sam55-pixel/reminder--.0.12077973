import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/reminder.dart';
import '../models/location.dart';
import '../services/notification_service.dart';
import '../services/geofence_service.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  DateTime? _selectedTime;
  double? _selectedLat;
  double? _selectedLng;

  String _triggerType = "Location"; // default
  String? _selectedPlace;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveAndSchedule() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack("Please enter a reminder title", Colors.red);
      return;
    }
    if (_triggerType == "Time" && _selectedTime == null) {
      _showSnack("Please pick a time", Colors.red);
      return;
    }
    if (_triggerType == "Location" && _selectedPlace == null) {
      _showSnack("Please select a saved location", Colors.red);
      return;
    }

    final box = Hive.box<Reminder>('reminders');
    final reminder = Reminder(
      title: _titleController.text.trim(),
      locationName: _triggerType == "Location" ? _selectedPlace : null,
      lat: _selectedLat,
      lng: _selectedLng,
      triggerType: _triggerType,
      scheduledTime: _triggerType == "Time" ? _selectedTime : null,
      created: DateTime.now(),
      active: true,
    );
    final key = await box.add(reminder);
    await reminder.save();

    // TIME REMINDER → LOUD ALARM
    if (_triggerType == "Time") {
      await NotificationService.scheduleExactAlarm(
        id: key,
        title: reminder.title,
        body: "Your reminder is here!",
        when: _selectedTime!,
      );
    }

    // LOCATION REMINDER → REGISTER GEOFENCE (WORKS OFFLINE)
    if (_triggerType == "Location") {
      await GeofenceService.addNewLocationReminder(reminder);
    }

    if (!mounted) return;
    _showSnack(
      _triggerType == "Time"
          ? "Loud alarm set for ${_formatTime(_selectedTime!)}!"
          : "Location reminder set for '$_selectedPlace'!",
      Colors.green,
    );
    Navigator.pop(context);
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Reminder"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "What should I remind you?",
                hintText: "e.g. Buy bread, Pray, Call Mom",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 30),

            // Trigger Type
            const Text("How should I remind you?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text("When I arrive at a place", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Home, Church, Market, Work"),
                    value: "Location",
                    groupValue: _triggerType,
                    onChanged: (v) => setState(() => _triggerType = v!),
                    secondary: const Icon(Icons.location_on, color: Colors.deepPurple),
                  ),
                  RadioListTile<String>(
                    title: const Text("At a specific time", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Medicine, Prayer time, Meetings"),
                    value: "Time",
                    groupValue: _triggerType,
                    onChanged: (v) => setState(() => _triggerType = v!),
                    secondary: const Icon(Icons.access_time, color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // TIME PICKER
            if (_triggerType == "Time") ...[
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                    if (time != null && mounted) {
                      setState(() {
                        _selectedTime = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.alarm, size: 32),
                  label: Text(
                    _selectedTime == null ? "Pick Time" : "Alarm: ${_formatTime(_selectedTime!)}",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],

            // LOCATION PICKER (OFFLINE SAVED LOCATIONS)
            if (_triggerType == "Location") ...[
              const Text("Choose a saved location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: Hive.box<StoredLocation>('locations').listenable(),
                builder: (context, Box<StoredLocation> box, _) {
                  final locations = box.values.toList();

                  if (locations.isEmpty) {
                    return Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.location_off, size: 60, color: Colors.orange),
                            const Text("No saved locations yet", style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.settings),
                              label: const Text("Go to Settings → Save Locations"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: locations.length,
                      itemBuilder: (context, i) {
                        final loc = locations[i];
                        final isSelected = _selectedPlace == loc.name;
                        return RadioListTile<String>(
                          title: Text(loc.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 17)),
                          subtitle: Text("Saved on ${DateFormat('dd MMM yyyy').format(loc.savedOn)}"),
                          value: loc.name,
                          groupValue: _selectedPlace,
                          onChanged: (val) {
                            setState(() {
                              _selectedPlace = val;
                              _selectedLat = loc.lat;
                              _selectedLng = loc.lng;
                            });
                          },
                          selected: isSelected,
                          activeColor: Colors.deepPurple,
                        );
                      },
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 40),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton(
                onPressed: _saveAndSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _triggerType == "Time" ? Colors.blueAccent : Colors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  _triggerType == "Time" ? "SET TIME REMINDER" : "SET LOCATION REMINDER",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
