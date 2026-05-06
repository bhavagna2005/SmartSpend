import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class EditGoalScreen extends StatefulWidget {
  final Map<String, dynamic> goal;

  const EditGoalScreen({super.key, required this.goal});

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _durationController;

  final Map<String, TextEditingController> _budgetControllers = {
    'Food': TextEditingController(),
    'Shopping': TextEditingController(),
    'Entertainment': TextEditingController(),
    'Transport': TextEditingController(),
    'Miscellaneous': TextEditingController(),
  };

  List<String> categoriesToCut = [
    'Food',
    'Shopping',
    'Entertainment',
    'Transport',
    'Miscellaneous',
  ];

  bool _isSaving = false;
  bool _isLoadingBudgets = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal['goal_name'] ?? '');
    _amountController = TextEditingController(
        text: (widget.goal['target_amount'] ?? '').toString());

    // Calculate remaining days from deadline
    final deadline = widget.goal['deadline'];
    if (deadline != null) {
      final days = DateTime.parse(deadline).difference(DateTime.now()).inDays;
      _durationController = TextEditingController(text: days.clamp(0, 9999).toString());
    } else {
      _durationController = TextEditingController(text: '30');
    }

    _loadExistingBudgets();
  }

  Future<void> _loadExistingBudgets() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final catData = await _supabase.from('categories').select();
      final budgetData = await _supabase
          .from('category_budgets')
          .select()
          .eq('user_id', userId);

      for (final budget in budgetData) {
        final cat = catData.firstWhere(
          (c) => c['category_id'] == budget['category_id'],
          orElse: () => {},
        );
        if (cat.isNotEmpty && _budgetControllers.containsKey(cat['category_name'])) {
          _budgetControllers[cat['category_name']]!.text =
              (budget['max_spend_limit'] ?? '').toString();
        }
      }
    } catch (_) {
      // Non-critical, proceed with empty fields
    } finally {
      if (mounted) setState(() => _isLoadingBudgets = false);
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final int days = int.tryParse(_durationController.text.trim()) ?? 30;
      final newDeadline = DateTime.now().add(Duration(days: days)).toIso8601String();

      // 1. Update the goal
      await _supabase.from('goals').update({
        'goal_name': _nameController.text.trim(),
        'target_amount': double.parse(_amountController.text.trim()),
        'deadline': newDeadline,
      }).eq(widget.goal.containsKey('goal_id') ? 'goal_id' : 'id', 
           widget.goal['goal_id'] ?? widget.goal['id']);

      // 2. Fetch category IDs
      final catData = await _supabase.from('categories').select();

      // 3. Upsert category budgets
      List<Map<String, dynamic>> budgetInserts = [];
      for (int i = 0; i < categoriesToCut.length; i++) {
        final catName = categoriesToCut[i];
        final catMatch = catData.firstWhere(
          (c) => c['category_name'] == catName,
          orElse: () => {},
        );
        if (catMatch.isEmpty) continue;
        budgetInserts.add({
          'user_id': userId,
          'category_id': catMatch['category_id'],
          'max_spend_limit':
              double.tryParse(_budgetControllers[catName]!.text) ?? 0.0,
          'priority_level': i + 1,
        });
      }
      await _supabase.from('category_budgets').upsert(
        budgetInserts,
        onConflict: 'user_id, category_id',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goal updated successfully! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true = refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('goals').delete().eq(
          widget.goal.containsKey('goal_id') ? 'goal_id' : 'id',
          widget.goal['goal_id'] ?? widget.goal['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal deleted.'), backgroundColor: Colors.red),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    for (final c in _budgetControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Edit Goal', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Delete Goal',
            onPressed: _deleteGoal,
          ),
        ],
      ),
      body: _isLoadingBudgets
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Goal Details'),
                    const SizedBox(height: 12),
                    _buildField(_nameController, 'Goal Name', Icons.flag_outlined),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            _amountController,
                            'Target Amount (₹)',
                            Icons.currency_rupee,
                            type: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            _durationController,
                            'Duration (Days)',
                            Icons.timer_outlined,
                            type: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('Monthly Budget Limits'),
                    const SizedBox(height: 4),
                    const Text(
                      'Drag to reorder priority. Top is cut first.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 14),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categoriesToCut.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = categoriesToCut.removeAt(oldIndex);
                          categoriesToCut.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final category = categoriesToCut[index];
                        return Card(
                          key: ValueKey(category),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.drag_handle,
                                    color: AppColors.primaryPurple),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(category,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: TextField(
                                    controller: _budgetControllers[category],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.right,
                                    decoration: const InputDecoration(
                                        hintText: 'Limit',
                                        prefixText: '₹ ',
                                        border: InputBorder.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryPurple,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryPurple, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primaryPurple, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (val) =>
            (val == null || val.isEmpty) ? 'Required' : null,
      ),
    );
  }
}
