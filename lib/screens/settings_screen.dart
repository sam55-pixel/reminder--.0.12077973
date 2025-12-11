import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_reminder/screens/locations_screen.dart';

import 'data_transparency_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: <Widget>[
          _buildSectionTitle(context, 'General'),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Manage Locations'),
            subtitle: const Text('Save and manage your frequently visited places'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LocationsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('Data Transparency'),
            subtitle: const Text('View all the data stored on your device'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DataTransparencyScreen()),
            ),
          ),
          const Divider(),
          _buildSectionTitle(context, 'Danger Zone'),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
            title: Text('Delete All Reminders', style: TextStyle(color: Colors.red.shade700)),
            onTap: () => _confirmDelete(context, 'reminders'),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
            title: Text('Delete All Settings', style: TextStyle(color: Colors.red.shade700)),
            onTap: () => _confirmDelete(context, 'settings'),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
            title: Text('Delete All Context History', style: TextStyle(color: Colors.red.shade700)),
            onTap: () => _confirmDelete(context, 'context'),
          ),
        ],
      ),
    );
  }

  Padding _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }

  void _showSnack(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String boxName) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete all $boxName? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red.shade700)),
              onPressed: () async {
                await Hive.box(boxName).clear();
                if (context.mounted) {
                  _showSnack(context, 'All $boxName have been deleted.', Colors.green);
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
