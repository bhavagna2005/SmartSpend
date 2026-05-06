import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 80),
                const Text("SmartSpend", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                const SizedBox(height: 10),
                const Text(AppStrings.loginSubtitle, style: TextStyle(color: AppColors.textGrey)),
                const SizedBox(height: 60),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                  validator: (val) => val!.isEmpty ? "Enter email" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock_outline)),
                  validator: (val) => val!.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, 
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Log In", style: TextStyle(color: Colors.white)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}