import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final Function(String) onCategorySelected;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        // --- ICON BASED ON CATEGORY ---
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getCategoryColor(transaction.category).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(transaction.category),
            color: _getCategoryColor(transaction.category),
          ),
        ),
        // --- TITLE AND SUBTITLE ---
        title: Text(
          transaction.sender,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "${transaction.formattedDate} • ${transaction.category}",
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
        // --- AMOUNT ---
        trailing: Text(
          "- ${CurrencyFormatter.formatNoDecimal(transaction.amount)}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
            fontSize: 16,
          ),
        ),
        // --- CLICK ACTION ---
        onTap: () => _showCategoryBottomSheet(context),
      ),
    );
  }

  // --- HELPER METHODS FOR UI ---
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food': return AppColors.foodGreen;
      case 'Shopping': return AppColors.shoppingOrange;
      case 'Transport': return AppColors.transportBlue;
      case 'Entertainment': return AppColors.entertainmentPurple;
      default: return AppColors.textGrey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Shopping': return Icons.shopping_bag;
      case 'Transport': return Icons.directions_bus;
      case 'Entertainment': return Icons.movie;
      default: return Icons.receipt_long;
    }
  }

  // --- QUICK ACTION MENU (BottomSheet) ---
  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Categorize Transaction",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildCategoryOption(context, Icons.restaurant, "Food", AppColors.foodGreen),
              _buildCategoryOption(context, Icons.shopping_bag, "Shopping", AppColors.shoppingOrange),
              _buildCategoryOption(context, Icons.directions_bus, "Transport", AppColors.transportBlue),
              _buildCategoryOption(context, Icons.movie, "Entertainment", AppColors.entertainmentPurple),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryOption(BuildContext context, IconData icon, String title, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: () {
        onCategorySelected(title);
        Navigator.pop(context); // Close sheet
      },
    );
  }
}