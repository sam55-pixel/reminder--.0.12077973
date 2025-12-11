import 'package:hive/hive.dart';

part 'location.g.dart';

@HiveType(typeId: 2) // New typeId for Location
class Location extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double latitude;

  @HiveField(2)
  double longitude;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}
