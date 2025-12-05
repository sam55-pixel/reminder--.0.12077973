import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder.dart';

class RemindersScreen extends StatelessWidget {
  final List<Reminder> reminders;
  final TextEditingController searchController;

  const RemindersScreen({
    super.key,
    required this.reminders,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    // FILTER WITH NULL-SAFE LOGIC
    final String query = searchController.text.toLowerCase().trim();

    final filteredReminders = reminders.where((r) {
      final titleMatch = r.title.toLowerCase().contains(query);
      final locationMatch = r.locationName != null
          ? r.locationName!.toLowerCase().contains(query)
          : false;
      return titleMatch || locationMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search reminders...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: filteredReminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 80, color: Colors.deepPurple.shade300),
                  const SizedBox(height: 16),
                  const Text("No reminders yet", style: TextStyle(fontSize: 20)),
                  const Text("Tap + to create your first reminder",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredReminders.length,
              itemBuilder: (context, index) {
                final r = filteredReminders[index];

                return Dismissible(
                  key: Key(r.key.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_forever,
                        color: Colors.white, size: 40),
                  ),
                  onDismissed: (_) async {
                    await Hive.box<Reminder>('reminders').delete(r.key);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${r.title}" deleted'),
                          backgroundColor: Colors.red.shade600,
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: r.triggerType == "Time"
                            ? Colors.blue.shade100
                            : Colors.green.shade100,
                        child: Icon(
                          r.triggerType == "Time"
                              ? Icons.access_time
                              : Icons.location_on,
                          color: r.triggerType == "Time"
                              ? Colors.blue.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                      title: Text(
                        r.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  r.locationName ?? "Time-based reminder",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: r.locationName == null
                                        ? Colors.blue.shade700
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                r.scheduledTime != null
                                    ? "Time: ${_formatTime(r.scheduledTime!)}"
                                    : "Trigger on arrival",
                                style: TextStyle(
                                  color: r.scheduledTime != null
                                      ? Colors.blue.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: r.active
                          ? Chip(
                              backgroundColor: Colors.green.shade100,
                              label: Text(
                                r.triggerType == "Time" ? "TIME" : "LOCATION",
                                style: TextStyle(
                                  color: r.triggerType == "Time"
                                      ? Colors.blue.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const Icon(Icons.notifications_off, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return hour == 0 ? '12:$minute $period' : '$hour:$minute $period';
  }
}