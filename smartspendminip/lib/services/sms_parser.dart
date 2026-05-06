class SMSParser {
  static Map<String, dynamic> extractDetails(String body) {
    // 1. EXTRACT AMOUNT
    // Matches: "debited by 500", "Rs. 500", "INR 500", "Amt: 500", "Rs 1,000.00"
    final amountRegex = RegExp(r'(?:debited\s+by|debited\s+from|spent\s+of|Rs\.?|INR|Amt[:\s]|₹|sent\s+of|transferred\s+of|paid|withdrawn)\s?([\d,]+\.?\d*)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(body);
    // Remove commas for parsing, handle potential null
    String amountStr = amountMatch?.group(1)?.replaceAll(',', '') ?? "0.0";
    double amount = double.tryParse(amountStr) ?? 0.0;

    // 2. EXTRACT DATE
    // Matches formats like: 01Jan25, 01-01-2025, 2025/01/01
    final dateRegex = RegExp(r'(\d{2}[a-zA-Z]{3}\d{2}|\d{2}[-/]\d{2}[-/]\d{2,4})');
    String date = dateRegex.firstMatch(body)?.group(1) ?? "Today";

    // 3. EXTRACT MERCHANT
    // Looks for words between typical triggers ("at", "to", "for") and separators
    String merchant = "Unknown Merchant";
    final merchantRegex = RegExp(r'(?:at|to|for|spent\s+on|pay\s+to|debited\s+to|paid\s+to|sent\s+to|transferred\s+to)\s+([\w\s\.]+?)(?=\s+on\s+\d|Ref|using|date|A/c|\d|$)', caseSensitive: false);
    final merchantMatch = merchantRegex.firstMatch(body);
    if (merchantMatch != null) {
      merchant = merchantMatch.group(1)!.trim();
    }

    // 4. IDENTIFY BANK (Simple heuristic based on SMS signature)
    String bank = "Other Bank";
    String upperBody = body.toUpperCase();
    if (upperBody.contains("SBI") || upperBody.contains("SBINB")) bank = "State Bank of India";
    else if (upperBody.contains("HDFC")) bank = "HDFC Bank";
    else if (upperBody.contains("ICICI")) bank = "ICICI Bank";
    else if (upperBody.contains("AXIS")) bank = "Axis Bank";
    else if (upperBody.contains("KOTAK")) bank = "Kotak Bank";

    return {
      "date": date,
      "amount": amount,
      "merchant": merchant,
      "bank": bank,
      "sms_text": body, // Needed for your ML model
    };
  }
}