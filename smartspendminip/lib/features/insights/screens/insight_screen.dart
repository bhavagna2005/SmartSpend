import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/category_color_helper.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isWeekly = true; // Toggle for Weekly vs Monthly

  // Data
  double _totalSpent = 0;
  double _dailyAllowance = 0;
  double _salary = 0;
  double _goalMonthlyTarget = 0;
  Map<String, Map<String, double>> _categoryAnalysis = {}; // {Name: {spent: X, limit: Y}}
  List<FlSpot> _trendSpots = [];
  String _smartSuggestion = "Loading your financial wisdom...";
  String _quirkyHeader = "Checking your pockets...";

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final startDate = _isWeekly 
          ? now.subtract(const Duration(days: 7)) 
          : now.subtract(const Duration(days: 30));

      // 1. Fetch Profile (Income)
      final profile = await _supabase
          .from('profiles')
          .select('monthly_income')
          .eq('id', user.id)
          .maybeSingle();
      final double salary = (profile?['monthly_income'] ?? 0).toDouble();

      // 2. Fetch Active Goal
      final goals = await _supabase
          .from('goals')
          .select('*')
          .eq('user_id', user.id)
          .eq('status', 'Active')
          .order('deadline', ascending: true)
          .limit(1);
      
      double goalMonthlyTarget = 0;
      if (goals.isNotEmpty) {
        final goal = goals[0];
        final target = (goal['target_amount'] ?? 0).toDouble();
        final current = (goal['current_amount'] ?? 0).toDouble();
        final remaining = target - current > 0 ? target - current : 0;
        final deadline = DateTime.parse(goal['deadline']);
        final daysLeft = deadline.difference(now).inDays;
        
        if (daysLeft > 0) {
          // How much more needs to be saved per day to reach target by deadline
          double dailySavingNeeded = remaining / daysLeft;
          goalMonthlyTarget = dailySavingNeeded * 30; // Normalized monthly save target
          _dailyAllowance = (salary - goalMonthlyTarget) / 30;
        } else {
          _dailyAllowance = salary / 30;
        }
      } else {
        _dailyAllowance = salary / 30;
      }

      _salary = salary;
      _goalMonthlyTarget = goalMonthlyTarget;

      // 3. Fetch Budgets
      final budgets = await _supabase
          .from('category_budgets')
          .select('*, categories(category_name)')
          .eq('user_id', user.id);

      // 4. Fetch Transactions for period
      final txs = await _supabase
          .from('transactions')
          .select('*, categories(category_name)')
          .eq('user_id', user.id)
          .gte('transaction_date', startDate.toIso8601String());

      // 5. Aggregate Data
      _totalSpent = 0;
      Map<String, double> tempSpent = {};
      Map<DateTime, double> dailyAgg = {};

      for (var tx in txs) {
        final amt = (tx['amount'] ?? 0).toDouble();
        final cat = tx['categories']?['category_name'] ?? 'Misc';
        final date = DateTime.parse(tx['transaction_date']);
        final dayOnly = DateTime(date.year, date.month, date.day);

        _totalSpent += amt;
        tempSpent[cat] = (tempSpent[cat] ?? 0) + amt;
        dailyAgg[dayOnly] = (dailyAgg[dayOnly] ?? 0) + amt;
      }

      // Build Category Analysis
      _categoryAnalysis = {};
      
      // First, add everything from budgets
      for (var b in budgets) {
        final name = b['categories']?['category_name'] ?? 'Misc';
        final limit = (b['max_spend_limit'] ?? 0).toDouble();
        _categoryAnalysis[name] = {
          'spent': tempSpent[name] ?? 0,
          'limit': limit,
        };
      }

      // Then, add categories that have spending but no explicit budget
      tempSpent.forEach((name, spent) {
        if (!_categoryAnalysis.containsKey(name)) {
          _categoryAnalysis[name] = {
            'spent': spent,
            'limit': 0, // No budget set
          };
        }
      });

      // Build Trend Spots
      _trendSpots = [];
      int days = _isWeekly ? 7 : 30;
      for (int i = 0; i < days; i++) {
        final d = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        _trendSpots.add(FlSpot((days - i).toDouble(), dailyAgg[d] ?? 0));
      }
      _trendSpots = _trendSpots.reversed.toList();

      _generateQuirkyMessages();

    } catch (e) {
      debugPrint("Error loading insights: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateQuirkyMessages() {
    String topCat = "None";
    double maxSpent = 0;
    int exhaustedCount = 0;
    int nearLimitCount = 0;

    _categoryAnalysis.forEach((name, data) {
      final spent = data['spent']!;
      final limit = data['limit']!;
      if (spent > maxSpent) {
        maxSpent = spent;
        topCat = name;
      }
      if (limit > 0) {
        if (spent >= limit) exhaustedCount++;
        else if (spent >= limit * 0.8) nearLimitCount++;
      }
    });

    // Determine Status
    double totalLimits = 0;
    _categoryAnalysis.values.forEach((v) => totalLimits += v['limit']!);

    if (exhaustedCount > 0) {
      _quirkyHeader = "Budget Exhausted 🛑";
      _smartSuggestion = "You have exhausted your limit in $exhaustedCount categories, notably $topCat. We recommend cutting back on non-essential spending for the remainder of the month.";
    } else if (nearLimitCount > 0) {
      _quirkyHeader = "Nearing Limits ⚠️";
      _smartSuggestion = "You are close to reaching your limits in $nearLimitCount categories. Your spending is highest in $topCat. Consider redistributing your remaining safe allowance.";
    } else if (_totalSpent > (_dailyAllowance * (_isWeekly ? 7 : 30)) * 1.1) {
      _quirkyHeader = "Spending High 📈";
      _smartSuggestion = "Your $topCat spending is higher than average for this period. To stay on track with your goals, a reduction of ₹${(_totalSpent - (_dailyAllowance * (_isWeekly ? 7 : 30))).toStringAsFixed(0)} is suggested.";
    } else {
      _quirkyHeader = "On Track ✅";
      _smartSuggestion = "Your finances are well-managed. You are currently on par to meet your saving goals. $topCat remains your primary area of expenditure.";
    }

    // Add extra wisdom if category limits are inconsistent with goal
    double disposableIncome = _salary - _goalMonthlyTarget;
    if (totalLimits > disposableIncome && totalLimits > 0) {
        _smartSuggestion += "\n\n⚠️ Note: Your total category budgets (₹${totalLimits.toStringAsFixed(0)}) exceed your monthly safe spend (₹${disposableIncome.toStringAsFixed(0)}). Consider adjusting your limits to reach your savings goal faster!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(onPressed: _loadAnalysis, icon: const Icon(Icons.refresh, color: AppColors.primaryPurple))
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAnalysis,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildToggle(),
                  const SizedBox(height: 25),
                  _buildQuirkyCard(),
                  const SizedBox(height: 25),
                  _buildDailyAllowanceCard(),
                  const SizedBox(height: 35),
                  const Text("Spending Trend", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildTrendGraph(),
                  const SizedBox(height: 35),
                  Text(
                    _isWeekly ? "Weekly Summary" : "Monthly Progress", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 15),
                  ..._categoryAnalysis.entries.map((e) => _buildCategoryRow(e.key, e.value['spent']!, e.value['limit']!)).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildToggle() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: Row(
        children: [
          Expanded(child: _toggleButton("Weekly", _isWeekly)),
          Expanded(child: _toggleButton("Monthly", !_isWeekly)),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool active) {
    return GestureDetector(
      onTap: () {
        if (!active) {
          setState(() => _isWeekly = text == "Weekly");
          _loadAnalysis();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuirkyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppColors.primaryPurple, size: 24),
              const SizedBox(width: 10),
              Text(_quirkyHeader, style: const TextStyle(color: AppColors.primaryPurple, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_smartSuggestion, style: const TextStyle(color: Color(0xFF4B4B4B), fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildDailyAllowanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: AppColors.primaryPurple.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Safe Daily Spend", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 5),
              Text("₹${_dailyAllowance.toStringAsFixed(0)}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const Icon(Icons.arrow_upward, size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text("Total: ₹${_totalSpent.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTrendGraph() {
    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 25, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _trendSpots.isEmpty ? [const FlSpot(0, 0)] : _trendSpots,
              isCurved: true,
              color: AppColors.primaryPurple,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [AppColors.primaryPurple.withOpacity(0.2), AppColors.primaryPurple.withOpacity(0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String name, double spent, double limit) {
    if (_isWeekly) {
      // Weekly view: Show status/prediction
      String status = "On Track";
      Color statusColor = AppColors.successGreen;
      
      // Heuristic: If week's spending is > 30% of monthly limit, it's trending high
      if (limit > 0) {
        if (spent > limit * 0.3) {
          status = "High Spend";
          statusColor = AppColors.expenseRed;
        } else if (spent > limit * 0.2) {
          status = "Check Limit";
          statusColor = AppColors.shoppingOrange;
        }
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Spent this week", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("₹${spent.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      );
    } else {
      // Monthly view: Show limits and progress bars
      double percent = (limit > 0) ? (spent / limit) : 0;
      if (percent > 1.0) percent = 1.0;
      
      Color color = CategoryColorHelper.getColor(name);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(10),
              minHeight: 10,
            ),
          ],
        ),
      );
    }
  }
}
