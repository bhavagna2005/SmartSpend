import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sms_engine.dart';

class NotificationService {
  static final SMSEngine _smsEngine = SMSEngine();

  /// Request the user to grant notification access in Android settings.
  static Future<bool> requestPermission() async {
    final status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      await NotificationListenerService.requestPermission();
    }
    return await NotificationListenerService.isPermissionGranted();
  }

  /// Start listening to notifications. Each notification text that looks
  /// like a bank debit SMS is sent through the existing [SMSEngine].
  static void startListening() {
    NotificationListenerService.notificationsStream.listen((event) {
      final title = event.title ?? '';
      final body = event.content ?? '';

      // Combine title + body so the parser has full context
      final fullText = '$title $body'.trim();

      if (fullText.isEmpty) return;

      print('🔔 Notification intercepted: $fullText');

      // Re-use the exact same debit-detection & save logic from SMSEngine
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _smsEngine.processAndSaveSms(
        fullText,
        onLog: (msg) => print('📋 $msg'),
      );
    });
  }
}
