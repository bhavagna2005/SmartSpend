import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:another_telephony/telephony.dart'; // Ensure this is the correct package
import '../../../core/constants/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final contactController = TextEditingController();
  final ageController = TextEditingController();
  final salaryController = TextEditingController();
  final professionController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Permanent SMS Permission Request
      await Telephony.instance.requestPhoneAndSmsPermissions;

      // 2. Auth Sign Up
      final response = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.user != null) {
        // 3. Insert Profile Data
        await Supabase.instance.client.from('profiles').insert({
          'id': response.user!.id,
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'contact_number': contactController.text.trim(),
          'age': int.tryParse(ageController.text.trim()) ?? 0,
          'monthly_income': double.tryParse(salaryController.text.trim()) ?? 0.0,
          'profession': professionController.text.trim(),
          'username': emailController.text.split('@').first,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created!")));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: _buildField(firstNameController, "First Name")),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(lastNameController, "Last Name")),
                ]),
                _buildField(emailController, "Email", type: TextInputType.emailAddress),
                _buildField(contactController, "Contact", type: TextInputType.phone),
                Row(children: [
                  Expanded(child: _buildField(ageController, "Age", type: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(salaryController, "Salary", type: TextInputType.number)),
                ]),
                _buildField(professionController, "Profession"),
                _buildField(passwordController, "Password", isPass: true),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign Up", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, {bool isPass = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPass,
        keyboardType: type,
        decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder()),
        validator: (val) => val!.isEmpty ? "Required" : null,
      ),
    );
  }
}