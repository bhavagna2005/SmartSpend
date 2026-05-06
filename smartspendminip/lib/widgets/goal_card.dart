import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/goal_model.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;

  const GoalCard({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              // Use an emoji or an Icon based on your goal.icon data
              Text(goal.icon, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 15),
          // Progress Bar
          LinearProgressIndicator(
            value: goal.progress,
            backgroundColor: AppColors.scaffoldBg,
            color: AppColors.primaryPurple,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(goal.progress * 100).toStringAsFixed(0)}% Completed",
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                ),
              ),
              Text(
                "${CurrencyFormatter.formatNoDecimal(goal.currentAmount)} / ${CurrencyFormatter.formatNoDecimal(goal.targetAmount)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}