import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ✅ Sign up with email & password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'http://localhost:3000/auth/callback',
    );
    return response;
  }

  // ✅ Sign in with email & password
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

  // ✅ Send password reset email
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email,
        redirectTo: 'http://localhost:3000/auth/callback');
  }

  // ✅ Update password
  Future<User?> updatePassword(String newPassword) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    return response.user;
  }

  // ✅ Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ✅ Get current user
  User? get currentUser => _client.auth.currentUser;
}
