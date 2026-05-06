import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:another_telephony/telephony.dart';
import 'package:intl/intl.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/sms_engine.dart';
import '../../../core/utils/category_color_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  final SMSEngine _smsEngine = SMSEngine();
  final Telephony telephony = Telephony.instance;

  // Notification listener
  StreamSubscription<dynamic>? _transactionSubscription;

  String userName = "User";
  List<Map<String, dynamic>> recentTransactions = [];
  Map<String, double> categoryTotals = {};
  bool _isLoading = true;
  int _touchedIndex = -1;
  final List<String> _inAppLogs = [];
  bool _showDebugConsole = false;

  void _addLog(String msg) {
    debugPrint(msg);
    if (mounted) {
      setState(() {
        _inAppLogs.insert(0, "${DateFormat('HH:mm:ss').format(DateTime.now())}: $msg");
        if (_inAppLogs.length > 50) _inAppLogs.removeLast();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initTransactionListener();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  void _initTransactionListener() {
    _transactionSubscription = SMSEngine.onNewTransaction.listen((_) {
      _addLog("🔄 New transaction detected! Refreshing...");
      if (mounted) _loadDashboardData();
    });
    _addLog("📡 Transaction Watcher: ACTIVE");
  }

  Future<void> _loadDashboardData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final profileData = await _supabase
          .from('profiles')
          .select('first_name')
          .eq('id', user.id)
          .maybeSingle();
      
      final txData = await _supabase
          .from('transactions')
          .select('*, categories(category_name)')
          .eq('user_id', user.id)
          .order('transaction_date', ascending: false);

      if (mounted) {
        // Calculate category totals from ALL transactions for the fixed 5 categories
        Map<String, double> totals = {
          'Food': 0,
          'Transport': 0,
          'Shopping': 0,
          'Entertainment': 0,
          'Misc': 0,
        };

        for (var tx in txData) {
          String cat = tx['categories']?['category_name'] ?? 'Misc';
          double amt = (tx['amount'] ?? 0).toDouble();
          
          if (totals.containsKey(cat)) {
            totals[cat] = (totals[cat] ?? 0) + amt;
          } else {
            totals['Misc'] = (totals['Misc'] ?? 0) + amt;
          }
        }

        setState(() {
          userName = profileData?['first_name'] ?? "User";
          // Limit the recent transactions list to only the latest 5 for the UI
          recentTransactions = List<Map<String, dynamic>>.from(txData.take(5));
          categoryTotals = totals;
          _isLoading = false;
        });
      }
    } catch (e) {
      _addLog("❌ Error loading dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildSpendingChart(),
                    if (_showDebugConsole) _buildDebugConsole(),
                    const SizedBox(height: 30),
                    const Text(
                      "Recent Activity", 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 15),
                    recentTransactions.isEmpty 
                      ? _buildEmptyState()
                      : Column(
                          children: recentTransactions
                              .map((tx) => _buildTransactionItem(tx))
                              .toList(),
                        ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onDoubleTap: () => setState(() => _showDebugConsole = !_showDebugConsole),
      onTap: () => Navigator.pushNamed(context, '/settings'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome back,", style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text("$userName 👋", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF7061FF), 
            child: Icon(Icons.person, color: Colors.white)
          ),
        ],
      ),
    );
  }

  Widget _buildDebugConsole() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      height: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SYSTEM LOGS", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.white, size: 16),
                onPressed: () => setState(() => _inAppLogs.clear()),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const Divider(color: Colors.green, thickness: 0.5),
          Expanded(
            child: ListView.builder(
              itemCount: _inAppLogs.length,
              itemBuilder: (context, i) => Text(
                _inAppLogs[i],
                style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    DateTime dt = DateTime.parse(tx['transaction_date']);
    String formattedDate = DateFormat('dd MMM, hh:mm a').format(dt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7061FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF7061FF)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  tx['merchant_name'] ?? 'Expense', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  tx['categories']?['category_name'] ?? 'Misc', 
                  style: const TextStyle(color: Colors.grey, fontSize: 13)
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "-₹${tx['amount']}", 
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
              ),
              Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text("No transactions recorded yet.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingChart() {
    bool hasData = categoryTotals.values.any((v) => v > 0);

    return Container(
      padding: const EdgeInsets.all(20),
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8)
          )
        ]
      ),
      child: Column(
        children: [
          const Text(
            "Spending Analysis", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          const SizedBox(height: 10),
          Expanded(
            child: !hasData 
              ? const Center(child: Text("No data yet", style: TextStyle(color: Colors.grey)))
              : PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    sections: _showingSections(),
                  ),
                ),
          ),
          if (hasData) ...[
            const SizedBox(height: 15),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: categoryTotals.keys.map((cat) => 
                _buildLegendItem(CategoryColorHelper.getColor(cat), cat)
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  List<PieChartSectionData> _showingSections() {
    final List<String> categories = categoryTotals.keys.toList();
    double total = categoryTotals.values.fold(0, (sum, val) => sum + val);

    return List.generate(categories.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 16.0 : 11.0;
      final radius = isTouched ? 50.0 : 40.0;
      final category = categories[i];
      final value = categoryTotals[category] ?? 0;
      final percentage = total > 0 ? (value / total * 100).toStringAsFixed(0) : "0";

      return PieChartSectionData(
        color: CategoryColorHelper.getColor(category),
        value: value > 0 ? value : 0.1, // Small value to show something if empty
        title: isTouched ? "$category\n$percentage%" : percentage + "%",
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
      );
    });
  }
}