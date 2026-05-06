import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/category_color_helper.dart';

class SpendingDonutChart extends StatefulWidget {
  final double totalSpent;
  // In a real app, this would be a List<CategoryModel>
  final Map<String, double> categoryData;

  const SpendingDonutChart({
    super.key,
    required this.totalSpent,
    required this.categoryData,
  });

  @override
  State<SpendingDonutChart> createState() => _SpendingDonutChartState();
}

class _SpendingDonutChartState extends State<SpendingDonutChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: _buildChartSections(),
                  ),
                ),
                // Center text showing total spent
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Total Spent",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                    Text(
                      CurrencyFormatter.formatNoDecimal(widget.totalSpent),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Legend
          const SizedBox(width: 10),
          _buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    List<PieChartSectionData> sections = [];
    int i = 0;
    widget.categoryData.forEach((category, amount) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 30.0 : 25.0;

      sections.add(
        PieChartSectionData(
          color: CategoryColorHelper.getColor(category),
          value: amount,
          title: '${((amount / widget.totalSpent) * 100).toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      i++;
    });
    return sections;
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.categoryData.keys.map((category) {
          Color color = CategoryColorHelper.getColor(category);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(category, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}