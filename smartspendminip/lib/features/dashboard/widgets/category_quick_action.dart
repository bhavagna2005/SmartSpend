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
        leading: CircleAvatar(
          backgroundColor: AppColors.lightPurple,
          child: const Icon(Icons.receipt, color: AppColors.primaryPurple),
        ),
        title: Text(
          transaction.sender,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${transaction.formattedDate} • ${transaction.category}",
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
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

  // --- QUICK ACTION MENU ---
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