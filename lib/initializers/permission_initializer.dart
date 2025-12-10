import '../services/permission_service.dart';

class PermissionInitializer {
  static Future<void> initialize() async {
    await PermissionService.requestInitialPermissions();
  }
}
