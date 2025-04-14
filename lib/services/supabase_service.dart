import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://usnbdpzauwstyzpkwjcr.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVzbmJkcHphdXdzdHl6cGt3amNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM0MTk5MjYsImV4cCI6MjA1ODk5NTkyNn0.rJOgsatrmPNN0chjMnLkLjZoHREnztAFLmm5IsHwxlQ',
    );
  }

  // Sign Up and Store User Data
  static Future<AuthResponse> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name}, // Storing name in auth metadata
      emailRedirectTo: 'mantramind://login', // Deep link for mobile app
    );

    if (response.user != null) {
      // Store additional user details in 'users' table
      await client.from('users').insert({
        'id': response.user!.id,
        'name': name,
        'email': email,
      });
    }

    return response;
  }

  // Check if the current user's email is verified
  static Future<bool> isEmailVerified() async {
    try {
      // Force retrieve a fresh session from the server
      await client.auth.refreshSession();

      // Get the current session after refresh
      final session = await client.auth.currentSession;

      // Get the user from the current session
      final user = session?.user;

      // Debug output
      print('Email verification status check:');
      print('User email: ${user?.email}');
      print('Email confirmed at: ${user?.emailConfirmedAt}');

      // Check if there's a user and if their email is confirmed
      return user?.emailConfirmedAt != null;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  // Alternative method to check email verification - directly query the user metadata
  static Future<bool> checkEmailVerificationStatus(
      String email, String password) async {
    try {
      // Try signing in - this will only succeed if the email is verified
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // If we can sign in and have metadata with confirmed email, it's verified
      return response.user?.emailConfirmedAt != null;
    } catch (e) {
      print('Error during verification status check: $e');
      return false;
    }
  }

  // Resend verification email to the user
  static Future<void> resendVerificationEmail(String email) async {
    await client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: 'mantramind://login',
    );
  }

  // Sign In
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
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

  // Save Disorder Selection
  static Future<void> saveUserDisorder(String disorder) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('user_disorders').insert({
      'user_id': user.id,
      'disorder': disorder,
    });
  }

  // Fetch User's Disorder
  static Future<List<Map<String, dynamic>>> getUserDisorder() async {
    final user = currentUser;
    if (user == null) return [];

    return await client.from('user_disorders').select().eq('user_id', user.id);
  }
}
