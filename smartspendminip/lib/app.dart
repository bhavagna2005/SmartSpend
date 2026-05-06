import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'shared/main_wrapper.dart';
// If you have a LoginScreen, import it here:
// import 'features/auth/screens/login_screen.dart';

class SmartBudgetApp extends StatelessWidget {
  const SmartBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartBudget AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        // Set the primary theme color
        primaryColor: AppColors.primaryPurple,
        // Define the default text theme using Google Fonts
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        // Configure App Bar theme globally
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.scaffoldBg,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.textDark),
        ),
      ),
      // --- INITIAL ROUTE ---
      // Start with the MainWrapper (Dashboard)
      // Switch to LoginScreen() if you want to implement auth first
      home: const MainWrapper(),
    );
  }
}