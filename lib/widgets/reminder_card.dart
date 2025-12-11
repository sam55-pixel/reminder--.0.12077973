import 'package:flutter/material.dart';
import '../models/reminder.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onToggle;
  final VoidCallback onDismiss;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onToggle,
    required this.onDismiss,
  });

  // Smart icon based on reminder type/title/location
  IconData get _icon {
    if (!reminder.active) return Icons.notifications_off;
    if (reminder.triggerType == "Time") return Icons.access_time_filled;

    final location = reminder.locationName?.toLowerCase().trim() ?? "";
    
    if (location.contains('home')) return Icons.home_filled;
    if (location.contains('work') || location.contains('office')) return Icons.work;
    if (location.contains('gym') || location.contains('fitness')) return Icons.fitness_center;
    if (location.contains('school') || location.contains('class')) return Icons.school;
    if (location.contains('church') || location.contains('mosque')) return Icons.mosque;
    if (location.contains('market') || location.contains('shop')) return Icons.store;
    
    return Icons.location_on;
  }

  // Smart color
  Color get _color {
    if (!reminder.active) return Colors.grey;
    if (reminder.triggerType == "Time") return Colors.blue.shade700;
    if (reminder.permanentlyBlockedIn.isNotEmpty) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  // Human readable time/context
  String get _timeContext {
    if (reminder.triggerType == "Time" && reminder.scheduledTime != null) {
      final time = reminder.scheduledTime!;
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return "At $hour:$minute $period";
    }
    return "When you arrive";
  }

  // Learned context message
  String get _context {
    final blocked = reminder.permanentlyBlockedIn;
    if (blocked.isEmpty) return "Delivers in all contexts";
    return "Never when: ${blocked.join(', ')}";
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(reminder.key),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade600,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 36),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: _color.withValues(alpha: 0.15),
            child: Icon(_icon, color: _color, size: 28),
          ),
          title: Text(
            reminder.title,
            style: const TextStyle(fontWeight:  FontWeight.bold, fontSize: 17),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(_timeContext, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  // Location chip (only show if exists)
                  if (reminder.locationName != null && reminder.locationName!.trim().isNotEmpty)
                    Chip(
                      label: Text(
                        reminder.locationName!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      avatar: const Icon(Icons.location_on, size: 16),
                      backgroundColor: Colors.green.shade50,
                    ),

                  // Time chip (for time reminders)
                  if (reminder.triggerType == "Time")
                    Chip(
                      label: const Text("TIME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.blue.shade100,
                    ),

                  // Learned AI chip
                  if (reminder.permanentlyBlockedIn.isNotEmpty || reminder.totalIgnores > 0)
                    Chip(
                      label: Text(
                        reminder.permanentlyBlockedIn.isNotEmpty
                            ? "Learned ($_context)"
                            : "Ignored ${reminder.totalIgnores} times",
                        style: const TextStyle(fontSize: 11),
                      ),
                      avatar: const Icon(Icons.auto_awesome, size: 16, color: Colors.orange),
                      backgroundColor: Colors.orange.shade50,
                    ),
                ],
              ),
            ],
          ),
          trailing: Switch(
  value: reminder.active,
  onChanged: (_) => onToggle(),
  thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
    if (states.contains(WidgetState.selected)) {
      return Colors.deepPurple; 
    }
    return Colors.grey; 
  }),
),
onTap: onDismiss,
        ),
      ),
    );
  }
}