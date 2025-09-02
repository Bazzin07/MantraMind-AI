import 'package:flutter/material.dart';
import 'package:mantramind/screens/auth/login_screen.dart';
import 'package:mantramind/screens/auth/signup_screen.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/services/sarvam_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mantramind/services/translation_debug_screen.dart';
import 'package:mantramind/screens/home/daily_diary_screen.dart';
import 'package:mantramind/screens/home/mood_tracking_screen.dart';
import 'package:mantramind/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Environment Variables
  try {
    await dotenv.load();
  } catch (e) {
    print("Error loading .env file: $e");
    // Continue with default values or show an error message
  }

  // Initialize Services safely so startup never blocks on failures
  try {
    SarvamService.initialize();
  } catch (e) {
    // Do not crash app if SARVAM_API_KEY is missing or invalid
    print('SarvamService initialization failed: $e');
  }

  try {
    await SupabaseService.initialize();
  } catch (e) {
    // Allow app to still boot (you can gate features on Supabase availability)
    print('Supabase initialization failed: $e');
  }

  // Schedule daily motivation after first frame (non-blocking) and catch errors
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.scheduleDailyMotivation(hour: 8, minute: 0)
        .catchError((e) => print('Notification schedule error: $e'));
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MantraMind',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Change to your brand color
        useMaterial3: true,
        fontFamily: 'Poppins', // Use your preferred font
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/debug/translation': (context) => const TranslationDebugScreen(),
        '/diary': (context) => const DailyDiaryScreen(),
        '/mood': (context) => const MoodTrackingScreen(),
        // Add other routes as needed
      },
    );
  }
}
