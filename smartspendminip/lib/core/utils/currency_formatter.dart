import 'package:intl/intl.dart';

class CurrencyFormatter {
  // 1. Standard Indian Rupee Format (e.g., ₹1,800.00)
  static final NumberFormat _rupeeFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // 2. Compact Indian Rupee Format (e.g., ₹1.8K or ₹1.2L)
  // This is perfect for the small labels on your "Spending Trend" charts
  static final NumberFormat _compactRupeeFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  /// Converts a double value to a full currency string: 1800.0 -> ₹1,800.00
  static String format(double amount) {
    return _rupeeFormat.format(amount);
  }

  /// Converts a double to a clean integer-style string: 1800.0 -> ₹1,800
  static String formatNoDecimal(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(amount);
  }

  /// Converts large numbers to compact versions: 100000.0 -> ₹1.0L
  static String formatCompact(double amount) {
    return _compactRupeeFormat.format(amount);
  }

  /// Helper to turn a String back into a double (useful when reading from Excel/Datasets)
  /// "₹1,800.00" -> 1800.0
  static double parseCurrencyString(String amountString) {
    try {
      // Removes symbols and commas before parsing
      String cleaned = amountString.replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }
}