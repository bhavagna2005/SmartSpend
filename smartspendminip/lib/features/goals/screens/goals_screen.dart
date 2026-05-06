import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/sms_engine.dart';
import 'edit_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> activeGoals = [];
  List<Map<String, dynamic>> _allTransactions = [];
  double _monthlyIncome = 0;
  StreamSubscription? _transactionSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
    _initTransactionListener();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  void _initTransactionListener() {
    _transactionSubscription = SMSEngine.onNewTransaction.listen((_) {
      if (mounted) _fetchGoals();
    });
  }

  Future<void> _fetchGoals() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // 1. Fetch Goals
      final goalData = await _supabase
          .from('goals')
          .select('*')
          .eq('user_id', user.id);

      // 2. Fetch Profile (Income)
      final profile = await _supabase
          .from('profiles')
          .select('monthly_income')
          .eq('id', user.id)
          .maybeSingle();

      // 3. Fetch All Transactions
      final txData = await _supabase
          .from('transactions')
          .select('amount, transaction_date')
          .eq('user_id', user.id);

      if (mounted) {
        setState(() {
          activeGoals = List<Map<String, dynamic>>.from(goalData);
          _monthlyIncome = (profile?['monthly_income'] ?? 0).toDouble();
          _allTransactions = List<Map<String, dynamic>>.from(txData);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching goals data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text("Savings Goals", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primaryPurple, size: 30),
            onPressed: () => Navigator.pushNamed(context, '/add-goal'),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : activeGoals.isEmpty 
          ? _buildEmptyState() 
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: activeGoals.length,
              itemBuilder: (context, index) {
                final goal = activeGoals[index];
                return GestureDetector(
                  onTap: () async {
                    final refreshed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditGoalScreen(goal: goal),
                      ),
                    );
                    if (refreshed == true) _fetchGoals();
                  },
                  child: _buildGoalCard(goal),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("No goals yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/add-goal'),
            child: const Text("Create Your First Goal"),
          )
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    // DYNAMIC CALCULATION
    final DateTime createdAt = DateTime.tryParse(goal['created_at'] ?? '') ?? DateTime.now();
    final int daysPassed = DateTime.now().difference(createdAt).inDays + 1; // +1 to avoid 0 division
    
    // Pro-rated Income since goal creation
    final double incomeToDate = (_monthlyIncome / 30) * daysPassed;
    
    // For "Shared Pool", we calculate savings as (Income since goal start - Expenses since goal start)
    double expensesSinceGoal = 0;
    for (var tx in _allTransactions) {
      final txDate = DateTime.tryParse(tx['transaction_date'] ?? '');
      if (txDate != null && txDate.isAfter(createdAt)) {
        expensesSinceGoal += (tx['amount'] ?? 0).toDouble();
      }
    }
    
    final double target = (goal['target_amount'] ?? 0).toDouble();
    final double saved = (incomeToDate - expensesSinceGoal).clamp(0.0, target); 
    final double remaining = (target - saved).clamp(0.0, target);
    final double progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal['goal_name'] ?? 'Unnamed Goal',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primaryPurple),
            ],
          ),
          const SizedBox(height: 6),
          Text("Target: ₹$target", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF0F0F0),
            color: AppColors.primaryPurple,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Saved", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    "₹${saved.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Remaining", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    "₹${remaining.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),

        ],
      ),
    );
  }
}