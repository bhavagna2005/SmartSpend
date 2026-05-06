import 'package:permission_handler/permission_handler.dart';

class SMSPermissionHandler {
  /// 1. Check the current status of SMS permissions
  /// Returns true if already granted, false otherwise.
  static Future<bool> hasPermission() async {
    PermissionStatus status = await Permission.sms.status;
    return status.isGranted;
  }

  /// 2. Request SMS permission from the user
  /// This triggers the system-level pop-up ("Allow SmartSpend to send and view SMS?")
  static Future<bool> requestPermission() async {
    PermissionStatus status = await Permission.sms.request();
    
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // If the user checked "Don't ask again", we need to open app settings
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// 3. A helper to handle the logic for your "Permission Required" screen
  /// This can be called when the user clicks the "Grant Permission" button 
  /// in your UI vision.
  static Future<void> handlePermissionFlow({
    required Function onGranted,
    required Function onDenied,
  }) async {
    bool granted = await requestPermission();
    if (granted) {
      onGranted();
    } else {
      onDenied();
    }
  }
}