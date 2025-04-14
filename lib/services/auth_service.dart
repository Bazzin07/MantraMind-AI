import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://usnbdpzauwstyzpkwjcr.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzbmJkcHphdXdzdHl6cGt3amNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0MTk5MjYsImV4cCI6MjA1ODk5NTkyNn0.rJOgsatrmPNN0chjMnLkLjZoHREnztAFLmm5IsHwxlQ',
    );
  }

  // Sign In
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign Up
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign Out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset Password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Get Current User
  static User? get currentUser => client.auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;
}