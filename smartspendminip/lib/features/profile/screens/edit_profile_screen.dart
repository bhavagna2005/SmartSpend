import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _ageController = TextEditingController();
  final _incomeController = TextEditingController();
  final _professionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        _firstNameController.text = data['first_name'] ?? '';
        _lastNameController.text = data['last_name'] ?? '';
        _contactController.text = data['contact_number'] ?? '';
        _ageController.text = (data['age'] ?? '').toString();
        _incomeController.text = (data['monthly_income'] ?? '').toString();
        _professionController.text = data['profession'] ?? '';
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'contact_number': _contactController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'monthly_income': double.tryParse(_incomeController.text.trim()) ?? 0.0,
        'profession': _professionController.text.trim(),
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully! ✓'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _ageController.dispose();
    _incomeController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar section
                    Center(
                      child: Stack(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primaryPurple,
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionLabel('Personal Info'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildField(_firstNameController, 'First Name', Icons.person_outline)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField(_lastNameController, 'Last Name', Icons.person_outline)),
                      ],
                    ),
                    _buildField(_contactController, 'Contact Number', Icons.phone_outlined,
                        type: TextInputType.phone),

                    const SizedBox(height: 20),
                    _buildSectionLabel('Financial Info'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(_ageController, 'Age', Icons.cake_outlined,
                              type: TextInputType.number, required: false),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(_incomeController, 'Monthly Income', Icons.currency_rupee,
                              type: TextInputType.number, required: false),
                        ),
                      ],
                    ),
                    _buildField(_professionController, 'Profession', Icons.work_outline, required: false),

                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryPurple,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool required = true,
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
            borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: required ? (val) => (val == null || val.isEmpty) ? 'Required' : null : null,
      ),
    );
  }
}
