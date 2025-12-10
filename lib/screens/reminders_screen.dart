import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/reminder.dart';
import '../services/ui_message_service.dart'; // Import the message service

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen for messages from background services
    UiMessageService.userMessage.addListener(_showUserMessage);
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Stop listening to avoid memory leaks
    UiMessageService.userMessage.removeListener(_showUserMessage);
    super.dispose();
  }

  // Method to display a SnackBar
  void _showUserMessage() {
    // Check if the widget is still mounted and a message exists.
    if (!mounted || UiMessageService.userMessage.value == null) return;

    // Capture the context and messenger beforehand.
    final messenger = ScaffoldMessenger.of(context);
    final message = UiMessageService.userMessage.value!;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade800,
      ),
    );
    // Clear the message so it doesn't show again
    UiMessageService.clearMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search reminders...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white),
          ),
          onChanged: (_) => setState(() {}),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Reminder>('reminders').listenable(),
        builder: (context, Box<Reminder> box, _) {
          final query = _searchController.text.toLowerCase().trim();
          final reminders = box.values.where((r) {
            final titleMatch = r.title.toLowerCase().contains(query);
            final locationMatch = r.locationName != null
                ? r.locationName!.toLowerCase().contains(query)
                : false;
            return titleMatch || locationMatch;
          }).toList();

          if (reminders.isEmpty) {
            return Center(
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
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final r = reminders[index];

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
                  // GOOD: Get ScaffoldMessenger before the await.
                  final messenger = ScaffoldMessenger.of(context);
                  final title = r.title; // Save title before deleting
                  await box.delete(r.key);

                  // GOOD: Use the captured messenger, and check if mounted.
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('"$title" deleted'),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
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
                    trailing: r.wasNotified
                        ? const Chip(
                            backgroundColor: Colors.grey,
                            label: Text("Notified"),
                          )
                        : (r.active
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
                            : const Icon(Icons.notifications_off, color: Colors.grey)),
                  ),
                ),
              );
            },
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
