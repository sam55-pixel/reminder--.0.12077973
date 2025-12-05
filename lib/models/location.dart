// lib/model/location.dart
import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 1) // Next ID after Reminder (0)
class StoredLocation extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double lat;

  @HiveField(2)
  double lng;

  @HiveField(3)
  DateTime savedOn;

  StoredLocation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.savedOn,
  });
}