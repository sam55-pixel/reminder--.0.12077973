import '../../services/notification_service.dart';

class NotificationInitializer {
  static Future<void> initialize() async {
    await NotificationService.init();
  }
}
