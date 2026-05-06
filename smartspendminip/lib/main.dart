import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/goals/screens/add_goals_screen.dart';
import 'features/profile/screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/sms_engine.dart';
import 'shared/main_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://uokdqbqakpogbpyxkooa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVva2RxYnFha3BvZ2JweXhrb29hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIyODM2MDQsImV4cCI6MjA4Nzg1OTYwNH0.FIXWTkv5_ixT35-75bzvOKfGwuQ7FU11KRlrb4hrbxA',
  );

  // Request notification/SMS access and start listening
  await NotificationService.requestPermission();
  NotificationService.startListening();
  await SMSEngine().startListening();

  runApp(const SmartSpendApp());
}

class SmartSpendApp extends StatelessWidget {
  const SmartSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Logic: If user is logged in, go to Home, else Login
      initialRoute: Supabase.instance.client.auth.currentSession == null ? '/login' : '/home',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainWrapper(),
        '/add-goal': (context) => const AddGoalScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}