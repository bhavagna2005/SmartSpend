import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/category_color_helper.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({super.key});

  @override
  Widget build(BuildContext context) {
    // --- DYNAMIC DATA (Will come from SMSEngine later) ---
    final double totalSpent = 1800.0;
    final double foodSpend = 450.0;
    final double shoppingSpend = 1200.0;
    final double othersSpend = 150.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Weekly Spending",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The actual Donut Chart
                PieChart(
                  PieChartData(
                    sectionsSpace: 6, // Space between sections
                    centerSpaceRadius: 70, // This creates the "Donut" hole
                    startDegreeOffset: -90,
                    sections: [
                      _buildSection(CategoryColorHelper.getColor('Food'), foodSpend),
                      _buildSection(CategoryColorHelper.getColor('Shopping'), shoppingSpend),
                      _buildSection(CategoryColorHelper.getColor('Others'), othersSpend),
                    ],
                  ),
                ),
                // Text inside the center hole
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Total Spent",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                    Text(
                      CurrencyFormatter.formatNoDecimal(totalSpent),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          // Legend below the chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend("Food", CategoryColorHelper.getColor('Food')),
              _buildLegend("Shopping", CategoryColorHelper.getColor('Shopping')),
              _buildLegend("Others", CategoryColorHelper.getColor('Others')),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to create the colored sections
  PieChartSectionData _buildSection(Color color, double value) {
    return PieChartSectionData(
      color: color,
      value: value,
      radius: 18, // Thickness of the donut ring
      showTitle: false,
    );
  }

  // Helper to create the legend dots
  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}