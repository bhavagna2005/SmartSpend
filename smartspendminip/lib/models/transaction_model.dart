import 'package:intl/intl.dart';

class TransactionModel {
  final String id; // Added ID for uniqueness
  final DateTime dateTime; // Using DateTime for proper sorting
  final double amount;
  final String merchant;
  final String bank;
  final String smsText;
  String category; // Made mutable so quick-action can update it

  TransactionModel({
    required this.id,
    required this.dateTime,
    required this.amount,
    required this.merchant,
    required this.bank,
    required this.smsText,
    required this.category,
  });

  // --- HELPER: FORMAT DATE FOR UI ---
  String get formattedDate => DateFormat('dd MMM yyyy').format(dateTime);
  String get sender => merchant;

  // --- JSON SERIALIZATION (For Database) ---
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      dateTime: DateTime.parse(json['dateTime']),
      amount: json['amount'].toDouble(),
      merchant: json['merchant'],
      bank: json['bank'],
      smsText: json['smsText'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'amount': amount,
      'merchant': merchant,
      'bank': bank,
      'smsText': smsText,
      'category': category,
    };
  }
}