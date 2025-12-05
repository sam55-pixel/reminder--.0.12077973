import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import '../models/reminder.dart';

class DataTransparencyScreen extends StatefulWidget {
  const DataTransparencyScreen({super.key});

  @override
  State<DataTransparencyScreen> createState() => _DataTransparencyScreenState();
}

class _DataTransparencyScreenState extends State<DataTransparencyScreen> {
  String _dbPath = "Loading...";
  List<Reminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dir = await getApplicationDocumentsDirectory();
    final box = Hive.box<Reminder>('reminders');

    if (!mounted) return;

    setState(() {
      _dbPath = dir.path;
      _reminders = box.values.toList();
    });
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
        title: const Text("Delete Reminder?"),
        content: Text(
          "Permanently delete:\n\n\"${reminder.title}\"\n\n${reminder.locationName != null ? "at ${reminder.locationName}" : "(Time-based reminder)"}",
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete Forever"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await reminder.delete();
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Deleted: ${reminder.title}"),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Map<String, dynamic> _reminderToMap(Reminder r) => {
        'key': r.key,
        'title': r.title,
        'location': r.locationName, // ← nullable, JSON handles null fine
        'lat': r.lat,
        'lng': r.lng,
        'trigger': r.triggerType,
        'active': r.active,
        'created': r.created.toIso8601String(),
        'scheduledTime': r.scheduledTime?.toIso8601String(),
        'ignoredContexts': r.ignoredContexts,
        'permanentlyBlockedIn': r.permanentlyBlockedIn,
      };

  IconData _getIcon(Reminder r) {
    if (!r.active) return Icons.notifications_off;
    if (r.triggerType == "Time") return Icons.access_time;
    return Icons.location_on;
  }

  Color _getColor(Reminder r) {
    if (!r.active) return Colors.grey;
    if (r.triggerType == "Time") return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Data – 100% On Your Device"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Delete ALL data",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  icon: const Icon(Icons.dangerous, color: Colors.red, size: 50),
                  title: const Text("NUKE ALL DATA?"),
                  content: const Text("This will delete every reminder forever.\n\nNo backup. No recovery."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Keep")),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("DELETE EVERYTHING"),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              await Hive.box<Reminder>('reminders').clear();
              await Hive.box('settings').clear();
              await _loadData();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All data erased from device"),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Stored Locally", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(
                      "Path:\n$_dbPath",
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "No servers • No cloud • No tracking • You own it",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Your ${_reminders.length} Reminder${_reminders.length == 1 ? '' : 's'} (Swipe to delete)",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _reminders.isEmpty
                  ? const Center(
                      child: Text(
                        "No reminders yet\nCreate one to see it here instantly",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _reminders.length,
                      itemBuilder: (context, index) {
                        final r = _reminders[index];
                        return Dismissible(
                          key: Key(r.key.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_forever, color: Colors.white, size: 32),
                          ),
                          confirmDismiss: (_) async {
                            await _deleteReminder(r);
                            return false;
                          },
                          child: Card(
                            child: ListTile(
                              leading: Icon(_getIcon(r), color: _getColor(r)),
                              title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                r.locationName ?? "(Time-based reminder)",
                                style: TextStyle(color: r.locationName == null ? Colors.grey : null),
                              ),
                              trailing: r.active
                                  ? const Icon(Icons.notifications_active, color: Colors.green)
                                  : const Icon(Icons.notifications_off, color: Colors.grey),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(r.title),
                                    content: SingleChildScrollView(
                                      child: SelectableText(
                                        const JsonEncoder.withIndent('  ').convert(_reminderToMap(r)),
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}