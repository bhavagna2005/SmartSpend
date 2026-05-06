import 'package:flutter/material.dart';
// Corrected Imports based on your specific folder tree
import '../features/dashboard/screens/dashboard_screen.dart'; 
import '../features/insights/screens/insight_screen.dart';
import '../features/goals/screens/goals_screen.dart';
import '../features/profile/screens/settings_screen.dart'; // Settings is in profile/screens/
import '../core/constants/app_colors.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Added InsightsScreen to the list
  final List<Widget> _screens = [
    const DashboardScreen(),
    const InsightsScreen(), 
    const GoalsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Using IndexedStack prevents the screens from re-loading every time you switch tabs
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Required for 4+ items
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes_rounded), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}