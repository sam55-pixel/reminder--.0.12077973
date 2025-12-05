import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/reminder.dart';
import '../models/location.dart';
import 'data_transparency_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  
  Future<void> _saveCurrentLocation(BuildContext context) async {
    // Permission check
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return;
        _showSnack(context, "Location permission denied", Colors.red);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      _showSnack(context, "Location denied forever → Open App Settings", Colors.red);
      await Geolocator.openAppSettings();
      return;
    }

    // GPS check
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;
      _showSnack(context, "Please turn on GPS", Colors.orange);
      await Geolocator.openLocationSettings();
      return;
    }

    // Show loading
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text("Getting location...")]),
      ),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      if (!context.mounted) return;
      Navigator.pop(context); // close loading

      // Ask for name
      final name = await showDialog<String>(
        context: context,
        builder: (_) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text("Name This Location"),
            content: TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: "e.g. Home, Work, Church", border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) Navigator.pop(context, text);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );

      if (name == null || name.isEmpty || !context.mounted) return;

      // Save to Hive
      final box = Hive.box<StoredLocation>('locations');
      final location = StoredLocation(
        name: name,
        lat: position.latitude,
        lng: position.longitude,
        savedOn: DateTime.now(),
      );
      await box.put(name.toLowerCase(), location);

      if (!context.mounted) return;
      _showSnack(
        context,
        "'$name' saved offline!",
        Colors.green,
        action: SnackBarAction(label: "View All", onPressed: () => _showSavedLocations(context)),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loading if still open
        _showSnack(context, "Failed to get location", Colors.red);
      }
    }
  }

  
  Future<void> _showSavedLocations(BuildContext context) async {
    final box = Hive.box<StoredLocation>('locations');
    if (box.isEmpty) {
      if (!context.mounted) return;
      _showSnack(context, "No saved locations yet", Colors.orange);
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Saved Locations (Offline)"),
        content: SizedBox(
          width: double.maxFinite,
          child: ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<StoredLocation> box, _) {
              final locations = box.values.toList();
              return ListView.builder(
                shrinkWrap: true,
                itemCount: locations.length,
                itemBuilder: (_, i) {
                  final loc = locations[i];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                    title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("Lat: ${loc.lat.toStringAsFixed(5)}, Lng: ${loc.lng.toStringAsFixed(5)}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () async {
                        await box.delete(loc.name.toLowerCase());
                        if (context.mounted) {
                          Navigator.pop(context);
                          _showSavedLocations(context);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  
  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.red, size: 50),
        title: const Text("Delete Everything?"),
        content: const Text("This will delete all reminders + saved locations permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete All"),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await Hive.box<Reminder>('reminders').clear();
    await Hive.box<StoredLocation>('locations').clear();

    if (context.mounted) {
      _showSnack(context, "All data deleted!", Colors.deepPurple);
    }
  }

  
  void _showSnack(BuildContext context, String message, Color color, {SnackBarAction? action}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, action: action),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminderBox = Hive.box<Reminder>('reminders');
    final locationBox = Hive.box<StoredLocation>('locations');

    return Scaffold(
      appBar: AppBar(title: const Text("Settings & Privacy"), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: ListTile(leading: Icon(Icons.auto_awesome, color: Colors.deepPurple), title: Text("Stoic Oracle v3.0"), subtitle: Text("Made in Akwa Ibom • Powered by Grok xAI"))),

        Card(child: ListTile(leading: const Icon(Icons.task_alt, color: Colors.green), title: const Text("Reminders"), subtitle: Text("${reminderBox.length} stored locally"))),
        Card(
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Colors.blue),
            title: const Text("Saved Locations"),
            subtitle: Text("${locationBox.length} offline places"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showSavedLocations(context),
          ),
        ),

        const SizedBox(height: 20),
        Card(child: ListTile(leading: const Icon(Icons.my_location, color: Colors.teal), title: const Text("Save Current Location"), subtitle: const Text("Name it Home, Work, etc."), onTap: () => _saveCurrentLocation(context))),
        Card(child: ListTile(leading: const Icon(Icons.privacy_tip, color: Colors.deepPurple), title: const Text("View All My Data"), trailing: const Icon(Icons.arrow_forward_ios), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataTransparencyScreen())))),

        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () => _clearAllData(context),
          icon: const Icon(Icons.delete_forever, size: 30),
          label: const Text("Delete All My Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        ),

        const SizedBox(height: 40),
        const Center(child: Text("Your data never leaves your phone\nNo cloud • Full privacy • Made in Akwa Ibom ❤️", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15))),
        const SizedBox(height: 30),
      ]),
    );
  }
}