import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:another_telephony/telephony.dart';
import 'sms_parser.dart';

// Background handler must be outside the class
@pragma('vm:entry-point')
void backGroundMessageHandler(SmsMessage message) async {
  print("📩 Background SMS Received: ${message.body}");
  final engine = SMSEngine();
  await engine.processAndSaveSms(message.body ?? "");
}

class SMSEngine {
  final Telephony telephony = Telephony.instance;
  final _supabase = Supabase.instance.client;

  // New broadcast stream to notify the UI when a new transaction is saved
  static final _onNewTransactionController = StreamController<void>.broadcast();
  static Stream<void> get onNewTransaction => _onNewTransactionController.stream;

  // Basic deduplication tracking
  static final Set<String> _processedHashes = {};

  Future<void> startListening() async {
    print("📡 Attempting to start SMS Listener...");
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted == true) {
      print("✅ SMS Permissions are ACTIVE");
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          print("📱 Foreground SMS: ${message.body}");
          processAndSaveSms(message.body ?? "");
        },
        onBackgroundMessage: backGroundMessageHandler,
      );
    } else {
      print("❌ SMS Permissions DENIED by user");
    }
  }

  Future<void> processAndSaveSms(String body, {Function(String)? onLog}) async {
    final bodyHash = body.trim().toLowerCase();
    if (_processedHashes.contains(bodyHash)) {
      onLog?.call("⏭️ Deduplicated: Message already processed.");
      return;
    }
    
    if (!_isDebitTransaction(body)) {
      onLog?.call("⏭️ Ignored: Not a debit transaction.");
      return;
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        onLog?.call("⚠️ Aborted: No user logged in.");
        return;
      }

      onLog?.call("🔍 Parsing SMS...");
      Map<String, dynamic> extracted = SMSParser.extractDetails(body);

      onLog?.call("🤖 Classifying category locally...");
      final merchant = (extracted['merchant'] ?? '').toString();
      final categoryId = _classifyLocally(body, merchant);
      onLog?.call("🤖 Category ID: $categoryId");

      onLog?.call("☁️ Saving to Cloud...");
      await _supabase.from('transactions').insert({
        'user_id': user.id,
        'category_id': categoryId,
        'amount': extracted['amount'],
        'merchant_name': merchant,
        'raw_message': body,
        'transaction_date': DateTime.now().toIso8601String(),
      });
      
      // Successfully saved! Mark as processed
      _processedHashes.add(bodyHash);
      if (_processedHashes.length > 100) _processedHashes.remove(_processedHashes.first);

      // Notify the UI
      _onNewTransactionController.add(null);
      
      onLog?.call("🚀 SUCCESS: Saved to Cloud!");
    } catch (e) {
      onLog?.call("❌ CRITICAL ERROR: $e");
    }
  }

  bool _isDebitTransaction(String body) {
    final lower = body.toLowerCase();
    return lower.contains("debited") ||
        lower.contains("debited from") ||
        lower.contains("spent") ||
        lower.contains("paid") ||
        lower.contains("payed") ||
        lower.contains("sent") ||
        lower.contains("transferred") ||
        lower.contains("vpa") ||
        lower.contains("withdrawal") ||
        lower.contains("withdrawn");
  }

  /// Offline keyword-based classifier — matches the SMS body + merchant name
  /// against curated keyword lists for each of the 5 Supabase categories.
  int _classifyLocally(String body, String merchant) {
    final text = '${body.toLowerCase()} ${merchant.toLowerCase()}';

    // ── Food (category_id = 1) ─────────────────────────────────────────────
    const foodKeywords = [
      'swiggy', 'zomato', 'dominos', 'domino', 'subway', 'mcdonald', 'kfc',
      'pizza', 'burger', 'cafe', 'coffee', 'restaurant', 'dhaba', 'biryani',
      'hotel', 'bakery', 'grocery', 'bigbasket', 'blinkit', 'zepto',
      'instamart', 'dunzo', 'milkbasket', 'grofers', 'dmart', 'reliance fresh',
      'more supermarket', 'star bazaar', 'fresh', 'haldiram', 'amul',
      'food', 'eat', 'snack', 'juice', 'canteen', 'mess',
    ];

    // ── Transport (category_id = 2) ────────────────────────────────────────
    const transportKeywords = [
      'uber', 'ola', 'rapido', 'indigo', 'spicejet', 'air india', 'vistara',
      'goindigo', 'akasa', 'irctc', 'railway', 'railways', 'metro',
      'redbus', 'abhibus', 'bus', 'ticket', 'petrol', 'fuel', 'diesel',
      'hp petrol', 'indian oil', 'bharat petroleum', 'bpcl', 'hpcl',
      'iocl', 'zoomcar', 'drivezy', 'makemytrip', 'easemytrip',
      'cleartrip', 'yatra', 'ixigo', 'goibibo', 'flight', 'train',
      'auto', 'cab', 'parking', 'toll', 'fastag',
    ];

    // ── Shopping (category_id = 3) ─────────────────────────────────────────
    const shoppingKeywords = [
      'amazon', 'flipkart', 'myntra', 'ajio', 'nykaa', 'snapdeal',
      'meesho', 'shopsy', 'lifestyle', 'westside', 'h&m', 'zara',
      'decathlon', 'reliance digital', 'croma', 'vijay sales',
      'samsung', 'apple store', 'oneplus', 'boat', 'noise',
      'pantaloons', 'max fashion', 'big bazaar', 'retail',
      'shop', 'store', 'mall', 'purchase', 'order',
    ];

    // ── Entertainment (category_id = 4) ───────────────────────────────────
    const entertainmentKeywords = [
      'netflix', 'amazon prime', 'hotstar', 'disney', 'prime video',
      'spotify', 'apple music', 'youtube', 'zee5', 'sonyliv', 'jiocinema',
      'bookmyshow', 'pvr', 'inox', 'cinepolis', 'movie', 'cinema',
      'concert', 'event', 'gaming', 'steam', 'pubg', 'battlegrounds',
      'game', 'play store', 'app store', 'subscription', 'ott',
    ];

    if (foodKeywords.any((k) => text.contains(k))) return 1;
    if (transportKeywords.any((k) => text.contains(k))) return 2;
    if (shoppingKeywords.any((k) => text.contains(k))) return 3;
    if (entertainmentKeywords.any((k) => text.contains(k))) return 4;

    // Default → Miscellaneous (category_id = 5)
    return 5;
  }
}