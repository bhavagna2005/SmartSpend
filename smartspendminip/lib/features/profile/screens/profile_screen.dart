import 'package:flutter/material.dart';
import 'package:smartspendminip/core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- USER HEADER ---
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryPurple,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 15),
            const Text(
              "Pranathi 👋",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            const Text(
              "pranathi@email.com",
              style: TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 40),

            // --- MENU ITEMS ---
            _buildMenuItem(Icons.settings_outlined, "Account Settings"),
            _buildMenuItem(Icons.security_outlined, "Privacy & Security"),
            _buildMenuItem(Icons.notifications_outlined, "Notifications"),
            _buildMenuItem(Icons.help_outline, "Help Center"),
            
            const SizedBox(height: 30),

            // --- LOGOUT BUTTON ---
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout",
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                // --- CORRECTED LOGOUT LOGIC ---
                // 1. Clear session data (if using SharedPreferences or Firebase)
                
                // 2. Navigate back to Login and remove all previous screens
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', // Ensure this route is defined in your main.dart
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white, // Replaced AppColors.cardWhite to avoid errors
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
        onTap: () {},
      ),
    );
  }
}