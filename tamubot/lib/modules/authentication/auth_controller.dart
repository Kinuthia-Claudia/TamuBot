import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the authentication state
class AuthState {
  final bool isAuthenticated;
  final User? user;

  AuthState({
    required this.isAuthenticated,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
    );
  }
}

/// Controller that manages authentication using Supabase
class AuthController extends StateNotifier<AuthState> {
  final SupabaseClient _client;

  AuthController(this._client) : super(AuthState(isAuthenticated: false));

  /// ---------------- SIGN UP ----------------
  Future<String?> signUp(
    String email,
    String password, {
    String? username,
    String? phone,
  }) async {
    try {
      print('🚀 Signup attempt for $email');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'phone': phone},
        emailRedirectTo: 'tamubot://auth/callback',
      );

      final user = response.user;

      if (user != null) {
        print('✅ User created: ${user.id}');

        await _client.from('profiles').upsert({
          'id': user.id,
          'username': username,
          'phone': phone,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        print('✅ Profile created in database');
        return "Please check your email to confirm your account.";
      } else {
        print('⚠️ No user returned (awaiting email confirmation).');
        return "Please check your email to confirm your account.";
      }
    } on AuthException catch (e) {
      print('❌ Auth error: ${e.message}');
      return e.message;
    } catch (e) {
      print('❌ General error: $e');
      return e.toString();
    }
  }

  /// ---------------- SIGN IN ----------------
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return "Invalid login credentials.";

      print('👤 User signed in: ${user.id}');
      final phone = await getUserPhone(user.id);

      if (phone != null && phone.isNotEmpty) {
        print('📲 Sending OTP to: $phone');
        try {
          await _client.auth.signInWithOtp(phone: phone);
          return phone; // Indicate OTP flow
        } catch (e) {
          print('❌ Error sending OTP: $e');
          return "Failed to send OTP. Please try again.";
        }
      } else {
        print('⚠️ No phone number found; proceeding directly to home.');
        state = state.copyWith(isAuthenticated: true, user: user);
        return null;
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// ---------------- SIGN IN WITH GOOGLE ----------------
  Future<String?> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'tamubot://auth/callback',
      );
      return null; // No error
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// ---------------- PHONE VERIFICATION ----------------
  Future<String?> sendOtpToPhone(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
      return "OTP sent successfully";
    } catch (e) {
      print('❌ Error sending OTP: $e');
      return e.toString();
    }
  }

  Future<String?> verifyPhoneOtp(String phone, String token) async {
    try {
      await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      return null; // success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return e.toString();
    }
  }

  /// ---------------- PROFILE MANAGEMENT ----------------
  Future<String?> getUserPhone(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('phone')
          .eq('id', userId)
          .maybeSingle();

      final phone = response?['phone'] as String?;
      print('📞 Retrieved phone: $phone');
      return phone;
    } catch (e) {
      print('❌ Error getting phone: $e');
      return null;
    }
  }

  Future<String?> updateUserPhone(String phone) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return "No user logged in";

      await _client.from('profiles').upsert({
        'id': user.id,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Phone updated: $phone');
      return null;
    } catch (e) {
      print('❌ Error updating phone: $e');
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error getting profile: $e');
      return null;
    }
  }

  /// ---------------- PASSWORD MANAGEMENT ----------------
  Future<String?> changePassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response.user != null
          ? "Password updated successfully."
          : "Password update failed.";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'tamubot://auth/callback',
      );
      return "Password reset email sent!";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// ---------------- SESSION MANAGEMENT ----------------
  Future<void> signOut() async {
    await _client.auth.signOut();
    state = AuthState(isAuthenticated: false);
  }

  void debugUserData() {
    final user = _client.auth.currentUser;
    print('=== USER DEBUG INFO ===');
    print('User ID: ${user?.id}');
    print('Email: ${user?.email}');
    print('Metadata: ${user?.userMetadata}');
    print('Confirmed: ${user?.emailConfirmedAt}');
    print('=====================');
  }
}

/// Provider for the AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final client = Supabase.instance.client;
  return AuthController(client);
});
