import 'package:flutter/material.dart';
import 'package:smart_reminder/models/location.dart';
import 'package:smart_reminder/services/location_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  late List<Location> _locations;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations() {
    setState(() {
      _locations = LocationService.getSavedLocations();
    });
  }

  Future<void> _addCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      final name = await _showNameLocationDialog();

      if (name != null && name.isNotEmpty) {
        await LocationService.saveLocation(
          name: name,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _loadLocations(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String?> _showNameLocationDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name This Location'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g., Home, Office'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(dynamic key) async {
    await LocationService.deleteLocation(key);
    _loadLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? const Center(
                  child: Text(
                    'No locations saved yet.\nTap the + button to add your current location.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    return ListTile(
                      title: Text(location.name),
                      subtitle: Text('Lat: ${location.latitude.toStringAsFixed(4)}, Lon: ${location.longitude.toStringAsFixed(4)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteLocation(location.key),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _addCurrentLocation,
        tooltip: 'Save Current Location',
        child: const Icon(Icons.add),
      ),
    );
  }
}
