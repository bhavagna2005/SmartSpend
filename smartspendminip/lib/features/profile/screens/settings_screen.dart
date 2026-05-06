import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text("Settings"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Row(
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: AppColors.primaryPurple, child: Icon(Icons.person, color: Colors.white)),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("My Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(user?.email ?? "User Email", style: const TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // Account Options
            _buildOption(
              context,
              Icons.person_outline,
              "Edit Profile",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            
            const Spacer(),
            
            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryPurple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}