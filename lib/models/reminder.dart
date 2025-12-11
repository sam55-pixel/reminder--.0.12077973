import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 0)
class Reminder extends HiveObject {
  @HiveField(0)
  String title;

  // New field for location key. Replaces locationName, lat, and lng.
  @HiveField(1)
  dynamic locationKey;

  @HiveField(2)
  String triggerType; // "Location" or "Time"

  @HiveField(3)
  DateTime? scheduledTime;

  @HiveField(4)
  DateTime created;

  @HiveField(5)
  bool active;

  @HiveField(6)
  String triggerMode; // "ARRIVE", "LEAVE", "BOTH" (for future use)

  @HiveField(7)
  Map<String, int> ignoredContexts;

  @HiveField(8)
  List<String> permanentlyBlockedIn;

  @HiveField(9)
  bool wasNotified;

  Reminder({
    required this.title,
    this.locationKey,
    required this.triggerType,
    this.scheduledTime,
    required this.created,
    this.active = true,
    this.triggerMode = "ARRIVE",
    Map<String, int>? ignoredContexts,
    List<String>? permanentlyBlockedIn,
    this.wasNotified = false,
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
  bool get isLocationBased => triggerType == "Location" && locationKey != null;

  @override
  String toString() {
    return 'Reminder("$title" - $triggerType at key: $locationKey)';
  }
}
