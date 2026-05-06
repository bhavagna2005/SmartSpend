class TransactionModel {
  final int? id;
  final String userId;
  final int categoryId;
  final double amount;
  final DateTime date;

  TransactionModel({this.id, required this.userId, required this.categoryId, required this.amount, required this.date});

  // Convert Supabase Map to Dart Object
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['transaction_id'],
      userId: map['user_id'],
      categoryId: map['category_id'],
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['transaction_date']),
    );
  }

  // Convert Dart Object to Map to save to Supabase
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'transaction_date': date.toIso8601String(),
    };
  }
}