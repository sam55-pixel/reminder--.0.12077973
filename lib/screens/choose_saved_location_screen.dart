import 'package:flutter/material.dart';
import 'package:smart_reminder/models/location.dart';
import 'package:smart_reminder/services/location_service.dart';

class ChooseSavedLocationScreen extends StatefulWidget {
  const ChooseSavedLocationScreen({super.key});

  @override
  State<ChooseSavedLocationScreen> createState() => _ChooseSavedLocationScreenState();
}

class _ChooseSavedLocationScreenState extends State<ChooseSavedLocationScreen> {
  late List<Location> _locations;

  @override
  void initState() {
    super.initState();
    _locations = LocationService.getSavedLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Saved Place')),
      body: _locations.isEmpty
          ? const Center(child: Text('You have no saved locations yet.'))
          : ListView.builder(
              itemCount: _locations.length,
              itemBuilder: (context, index) {
                final location = _locations[index];

                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(location.name),
                  onTap: () => Navigator.pop(context, location),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteLocation(location),
                  ),
                );
              },
            ),
    );
  }

  void _deleteLocation(Location location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location?'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              LocationService.deleteLocation(location.key);
              setState(() {
                _locations.remove(location);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location deleted'), backgroundColor: Colors.red),
              );
            },
          ),
        ],
      ),
    );
  }
}
