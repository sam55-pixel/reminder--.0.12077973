import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_reminder/models/location.dart';

class LocationService {
  static const String _boxName = 'locations';

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(LocationAdapter().typeId)) {
      Hive.registerAdapter(LocationAdapter());
    }
    await Hive.openBox<Location>(_boxName);
  }

  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  static Future<void> saveLocation({
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final box = Hive.box<Location>(_boxName);
    final location = Location(
      name: name,
      latitude: latitude,
      longitude: longitude,
    );
    await box.add(location);
  }

  static List<Location> getSavedLocations() {
    final box = Hive.box<Location>(_boxName);
    return box.values.toList();
  }

  static Future<void> deleteLocation(dynamic key) async {
    final box = Hive.box<Location>(_boxName);
    await box.delete(key);
  }
}
