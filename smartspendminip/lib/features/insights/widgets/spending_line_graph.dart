import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class SpendingLineGraph extends StatefulWidget {
  // Expected format: FlSpot(dayIndex, amount)
  final List<FlSpot> dataPoints;

  const SpendingLineGraph({super.key, required this.dataPoints});

  @override
  State<SpendingLineGraph> createState() => _SpendingLineGraphState();
}

class _SpendingLineGraphState extends State<SpendingLineGraph> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(10, 25, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          // --- INTERACTION ---
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.primaryPurple,
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    CurrencyFormatter.formatNoDecimal(barSpot.y),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _bottomTitleWidgets,
                reservedSize: 32,
                interval: 1,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          // --- DATA CONFIGURATION ---
          lineBarsData: [
            LineChartBarData(
              spots: widget.dataPoints,
              isCurved: true,
              color: AppColors.primaryPurple,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false), // Hide dots
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primaryPurple.withOpacity(0.1), // Gradient fill
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for X-axis labels (Mon, Wed, Fri)
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(color: AppColors.textGrey, fontSize: 12, fontWeight: FontWeight.w500);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Mon'; break;
      case 2: text = 'Wed'; break;
      case 4: text = 'Fri'; break;
      case 6: text = 'Sun'; break;
      default: text = ''; break;
    }

    return SideTitleWidget(
      axisSide: AxisSide.bottom,
      space: 10,
      child: Text(text, style: style),
    );
  }
}