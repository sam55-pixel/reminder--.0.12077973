import 'package:hive/hive.dart';

part 'reminder.g.dart';


@HiveType(typeId: 0)
class Reminder extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String? locationName;  
  @HiveField(2)
  double? lat;

  @HiveField(3)
  double? lng;

  @HiveField(4)
  String triggerType; // "Location" or "Time"

  @HiveField(5)
  DateTime? scheduledTime;

  @HiveField(6)
  DateTime created;

  @HiveField(7)
  bool active;

  @HiveField(8)
  String triggerMode; // "ARRIVE", "LEAVE", "BOTH"

  @HiveField(9)
  Map<String, int> ignoredContexts;

  @HiveField(10)
  List<String> permanentlyBlockedIn;

  Reminder({
    required this.title,
    this.locationName,                    // ← NOW OPTIONAL
    this.lat,
    this.lng,
    required this.triggerType,
    this.scheduledTime,
    required this.created,
    this.active = true,
    this.triggerMode = "ARRIVE",
    Map<String, int>? ignoredContexts,
    List<String>? permanentlyBlockedIn,
  })  : ignoredContexts = ignoredContexts ?? <String, int>{},
        permanentlyBlockedIn = permanentlyBlockedIn ?? <String>[];

  /// Call when user ignores reminder in a context
  void ignored(String context) {
    ignoredContexts[context] = (ignoredContexts[context] ?? 0) + 1;
  }

  /// Permanently block this reminder in a context
  void blockInContext(String context) {
    if (!permanentlyBlockedIn.contains(context)) {
      permanentlyBlockedIn.add(context);
    }
  }

  /// Check if reminder should be blocked in current context
  bool isBlockedIn(String context) {
    return permanentlyBlockedIn.contains(context);
  }

  /// Get total ignore count
  int get totalIgnores => ignoredContexts.values.fold(0, (a, b) => a + b);

  bool get isTimeBased => triggerType == "Time";
  bool get isLocationBased => triggerType == "Location";

  @override
  String toString() {
    return 'Reminder("$title" - $triggerType${locationName != null ? " at $locationName" : ""})';
  }
}