import 'dart:convert';
import 'package:http/http.dart' as http;

class APIService {
  // 1. Keep the base URL as the root IP
  static const String baseUrl = "http://192.168.68.57:5000";
  static const Duration _timeoutDuration = Duration(seconds: 10); // Increased slightly for stability

  static Future<String> predictCategory(String smsText) async {
    try {
      // 2. IMPORTANT: You must add "/predict" to the Uri.parse line
      print("🌐 Sending request to: $baseUrl/predict");
      final response = await http.post(
        Uri.parse("$baseUrl/predict"), 
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        // 3. Make sure the key matches what your Python code expects (usually "text" or "message")
        body: jsonEncode({"text": smsText}),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        // Returns the category from your ML model
        return data['category'] ?? "Miscellaneous"; 
      } else {
        print("❌ API Error: Status ${response.statusCode}");
        return "Miscellaneous";
      }
    } catch (e) {
      print("⚠️ API Connection Error: $e");
      return "Miscellaneous";
    }
  }
}