import 'package:flutter/material.dart';

class MapContextScreen extends StatelessWidget {
  final String locationText;
  final String currentActivity;

  const MapContextScreen({
    super.key,
    required this.locationText,
    required this.currentActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stoic AI • Live Context"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.black],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AI Icon
              const Icon(
                Icons.smart_toy,
                size: 120,
                color: Colors.white,
              ),
              const SizedBox(height: 30),

              // Location
              const Text(
                "Your Current Location",
                style: TextStyle(fontSize: 22, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  locationText,
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 50),

              // Activity
              const Text(
                "Your Current Activity",
                style: TextStyle(fontSize: 22, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Text(
                currentActivity,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),

              // Stoic Message
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "The Oracle watches. It learns from you.\n"
                  "It knows when to speak... and when to remain silent.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 60),

              // Smart Delivery Rules
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                color: Colors.white.withOpacity(0.1),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text("Smart Delivery Rules", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 12),
                      _Rule(text: "STILL → Reminder delivered", color: Colors.green),
                      _Rule(text: "WALKING → Reminder delivered", color: Colors.green),
                      _Rule(text: "RUNNING → Waiting wisely...", color: Colors.orange),
                      _Rule(text: "IN VEHICLE → Waiting wisely...", color: Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for rules
class _Rule extends StatelessWidget {
  final String text;
  final Color color;

  const _Rule({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontSize: 16)),
        ],
      ),
    );
  }
}
