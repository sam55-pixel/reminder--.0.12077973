import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smart_reminder/models/location.dart';
import 'package:smart_reminder/services/context_service.dart';
import '../models/reminder.dart';
import '../services/ui_message_service.dart';

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
    UiMessageService.userMessage.addListener(_showUserMessage);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    UiMessageService.userMessage.removeListener(_showUserMessage);
    super.dispose();
  }

  void _showUserMessage() {
    if (!mounted || UiMessageService.userMessage.value == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final message = UiMessageService.userMessage.value!;
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue.shade800),
    );
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
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: ContextService.getCurrentActivity(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading context"));
          }

          final currentContext = snapshot.data ?? "UNKNOWN";

          return ValueListenableBuilder(
            valueListenable: Hive.box<Reminder>('reminders').listenable(),
            builder: (context, Box<Reminder> box, _) {
              final query = _searchController.text.toLowerCase().trim();
              final locationsBox = Hive.box<Location>('locations');

              final reminders = box.values.where((r) {
                if (query.isEmpty) return true;
                final titleMatch = r.title.toLowerCase().contains(query);
                bool locationMatch = false;
                if (r.isLocationBased) {
                  final location = locationsBox.get(r.locationKey);
                  if (location != null) {
                    locationMatch = location.name.toLowerCase().contains(query);
                  }
                }
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
                  final ignoredCount = r.ignoredContexts[currentContext] ?? 0;

                  String? locationName;
                  if (r.isLocationBased) {
                    final location = locationsBox.get(r.locationKey);
                    locationName = location?.name;
                  }

                  return Dismissible(
                    key: Key(r.key.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete_forever, color: Colors.white, size: 40),
                    ),
                    onDismissed: (_) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final title = r.title;
                      await box.delete(r.key);
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ListTile(
                            isThreeLine: true,
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor: r.isTimeBased ? Colors.blue.shade100 : Colors.green.shade100,
                              child: Icon(
                                r.isTimeBased ? Icons.access_time : Icons.location_on,
                                color: r.isTimeBased ? Colors.blue.shade700 : Colors.green.shade700,
                              ),
                            ),
                            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        locationName ?? "Time-based reminder",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: locationName == null ? Colors.blue.shade700 : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (r.scheduledTime != null)
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Time: ${DateFormat('h:mm a').format(r.scheduledTime!)}",
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: r.wasNotified
                                ? const Chip(backgroundColor: Colors.grey, label: Text("Notified"))
                                : (r.active
                                    ? Chip(
                                        backgroundColor: r.isTimeBased ? Colors.blue.shade100 : Colors.green.shade100,
                                        label: Text(
                                          r.triggerType.toUpperCase(),
                                          style: TextStyle(
                                            color: r.isTimeBased ? Colors.blue.shade700 : Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.notifications_off, color: Colors.grey)),
                          ),
                          if (ignoredCount > 3 && !r.isBlockedIn(currentContext))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: TextButton(
                                onPressed: () {
                                  r.blockInContext(currentContext);
                                  r.save();
                                  // No need for setState since ValueListenableBuilder will handle it
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Reminder blocked for "$currentContext" context.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                },
                                child: Text('You often ignore this while $currentContext. Block in this context?'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
