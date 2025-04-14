import 'package:flutter/material.dart';
import 'package:mantramind/screens/auth/login_screen.dart';
import 'package:mantramind/screens/auth/signup_screen.dart';
import 'package:mantramind/services/supabase_service.dart';
import 'package:mantramind/services/sarvam_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mantramind/services/translation_debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Environment Variables
  try {
    await dotenv.load();
  } catch (e) {
    print("Error loading .env file: $e");
    // Continue with default values or show an error message
  }

  // Initialize Services
  SarvamService.initialize();
  await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        // Add other routes as needed
      },
    );
  }
}
