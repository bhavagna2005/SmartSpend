import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryPurple, // Use constant
      unselectedItemColor: AppColors.textGrey,    // Use constant
      showUnselectedLabels: true,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.track_changes_rounded),
          label: "Goals",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: "Insights",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}