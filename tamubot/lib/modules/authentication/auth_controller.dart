
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the authentication state
class AuthState {
  final bool isAuthenticated;
  final User? user;

  AuthState({required this.isAuthenticated, this.user});

  AuthState copyWith({bool? isAuthenticated, User? user}) {
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

  /// Sign up with email & password
  Future<String?> signUp(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.testerapp://login-callback', // 👈 deep link
      );

      if (response.user != null) {
        // Email confirmation required → don't mark as logged in yet
        return "Please check your email to confirm your account.";
      } else {
        return "Sign-up failed: No user returned.";
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// Sign in with email & password
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = state.copyWith(isAuthenticated: true, user: response.user);
        return null; // success
      } else {
        return "Invalid login credentials.";
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
/// Sign in with Google
Future<String?> signInWithGoogle() async {
  try {
    // This opens the browser for the OAuth flow
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.testerapp://login-callback', // 👈 for mobile deep linking
    );

      return null; // success, Supabase will handle session persistence
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}
/// Sign in with phone number (sends OTP SMS)
Future<String?> signInWithPhone(String phoneNumber) async {
  try {
    await _client.auth.signInWithOtp(
      phone: phoneNumber,
    );
    return "OTP sent to $phoneNumber";
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

/// Verify OTP for phone sign-in
Future<String?> verifyPhoneOtp(String phoneNumber, String otp) async {
  try {
    final response = await _client.auth.verifyOTP(
      phone: phoneNumber,
      token: otp,
      type: OtpType.sms,
    );

    if (response.user != null) {
      state = state.copyWith(isAuthenticated: true, user: response.user);
      return null; // success
    } else {
      return "Invalid OTP.";
    }
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

  /// Sign out the current user
  Future<void> signOut() async {
    await _client.auth.signOut();
    state = AuthState(isAuthenticated: false);
  }

  /// 🔑 Change password (when logged in)
  Future<String?> changePassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (response.user != null) {
        return "Password updated successfully.";
      } else {
        return "Password update failed.";
      }
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// 🔑 Forgot password (send reset email)
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: "io.testerapp://resetpassword", // 👈 must match deep link setup
      );
      return "Password reset email sent!";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Provider for the AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final client = Supabase.instance.client;
  return AuthController(client);
});
