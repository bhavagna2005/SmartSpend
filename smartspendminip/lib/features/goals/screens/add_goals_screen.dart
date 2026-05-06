import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController(); // Added for duration
  bool _isSaving = false;

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
    'Miscellaneous'
  ];

  Future<void> _saveGoalAndBudgets() async {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty || _durationController.text.isEmpty) {
      _showSnackBar("Please fill in all Goal details", Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      // Calculate deadline based on user input (Assuming input is in Days)
      final int days = int.tryParse(_durationController.text) ?? 30;
      final deadlineDate = DateTime.now().add(Duration(days: days)).toIso8601String();

      // 1. Save the Main Goal
      await supabase.from('goals').insert({
        'user_id': user!.id,
        'goal_name': _nameController.text.trim(),
        'target_amount': double.parse(_amountController.text),
        'status': 'Active',
        'deadline': deadlineDate,
      });

      // 2. Fetch Category IDs
      final catData = await supabase.from('categories').select();
      
      // 3. Prepare Batch Insert
      List<Map<String, dynamic>> budgetInserts = [];
      for (int i = 0; i < categoriesToCut.length; i++) {
        String catName = categoriesToCut[i];
        final catId = catData.firstWhere((c) => c['category_name'] == catName)['category_id'];
        
        budgetInserts.add({
          'user_id': user.id,
          'category_id': catId,
          'max_spend_limit': double.tryParse(_budgetControllers[catName]!.text) ?? 0.0,
          'priority_level': i + 1,
        });
      }

      // 4. Upsert category_budgets
      await supabase.from('category_budgets').upsert(
        budgetInserts,
        onConflict: 'user_id, category_id',
      );

      if (mounted) {
        _showSnackBar("Goal and Budgets set!", Colors.green);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text("Plan Your Savings"), centerTitle: true, elevation: 0, backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Step 1: Set Your Goal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildInputLabel("Goal Name"),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: "e.g. New Laptop")),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Target Amount"),
                      TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "₹ 0", prefixText: "₹ ")),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputLabel("Duration (Days)"),
                      TextField(controller: _durationController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "e.g. 30")),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 35),
            const Text("Step 2: Monthly Limits & Priority", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Drag to reorder priority. Top is cut first.", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 15),

            // Reorderable List with Budget Inputs
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.drag_handle, color: AppColors.primaryPurple),
                        const SizedBox(width: 15),
                        Expanded(child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold))),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _budgetControllers[category],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(hintText: "Limit", border: InputBorder.none),
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
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveGoalAndBudgets,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Plan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey));
}