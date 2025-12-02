import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  //  Sign up with email & password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'tamubot://auth/callback',
    );
    return response;
  }

  // Sign in with email & password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Send OTP to user's email
  Future<void> sendEmailOtp(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'tamubot://auth/callback', 
    );
  }

  /// Verify OTP entered by the user
  Future<void> verifyEmailOtp(String email, String token) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
    if (response.session == null) {
      throw Exception('OTP verification failed');
    }
  }

  //  Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email,
        redirectTo: 'tamubot://auth/callback');
  }

  //  Update password
  Future<User?> updatePassword(String newPassword) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    return response.user;
  }

  //  Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current user
  User? get currentUser => _client.auth.currentUser;
}
