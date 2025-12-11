import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationInitializer {
  static Future<void> initialize() async {
    final notifications = FlutterLocalNotificationsPlugin();
    await notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );
  }
}
