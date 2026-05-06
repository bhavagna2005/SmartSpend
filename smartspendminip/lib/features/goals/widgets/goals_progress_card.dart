import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class GoalProgressCard extends StatelessWidget {
  final String goalName;
  final double targetAmount;
  final double currentAmount;

  const GoalProgressCard({
    super.key,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    double progress = currentAmount / targetAmount;
    if (progress > 1.0) progress = 1.0; // Cap at 100%

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: AppColors.lightBlueTint, // Blue tint from your SS
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal Name
          Text(
            goalName,
            style: const TextStyle(
              color: AppColors.transportBlue, // Matching text color
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          // Progress Title
          Text(
            "You are ${(progress * 100).toStringAsFixed(0)}% on track",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white, // Background of the bar
              color: AppColors.transportBlue, // Filled color
            ),
          ),
          const SizedBox(height: 15),
          // Amounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.formatNoDecimal(currentAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                CurrencyFormatter.formatNoDecimal(targetAmount),
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}