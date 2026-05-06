import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      // --- BACK BUTTON ---
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      // --- TITLE ---
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      // --- RIGHT ACTIONS (e.g., Profile Icon) ---
      actions: actions,
    );
  }

  // --- REQUIRED FOR PREFERREDSIZEWIDGET ---
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}