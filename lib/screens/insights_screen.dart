import 'package:flutter/material.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stoic Intelligence")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb, color: Colors.amber, size: 40),
                title: const Text("You respond 92% faster when walking"),
                subtitle: const Text("We now prioritize walking context for urgent reminders"),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.thumb_down, color: Colors.red, size: 40),
                title: const Text("Gym reminders ignored 7× when running"),
                subtitle: const Text("Auto-postponed until you're still or walking"),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.purple, size: 40),
                title: const Text("Auto-suggested: Drink water every 2h when still"),
                subtitle: const Text("Based on your sedentary patterns"),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Stoic AI is learning from your behavior every day",
                style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}