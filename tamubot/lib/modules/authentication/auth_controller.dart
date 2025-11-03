import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Sign up with email & password and create profile
  Future<String?> signUp(
    String email,
    String password, {
    String? username,
    String? phone,
  }) async {
    try {
      print('🚀 Signup attempt:');
      print('   Email: $email');
      print('   Phone: $phone');
      print('   Username: $username');

      // Step 1: Create the user account
     final response = await _client.auth.signUp(
 
  email: email,
  password: password,
  data: {
    'phone': phone,
  },
  emailRedirectTo: 'tamubot://auth/callback',
);

// ✅ Fix: Handle cases where user is not immediately available
final user = response.user;

if (user != null) {
  print('✅ User created: ${user.id}');
  
  // Step 2: Create user profile in profiles table
  await _client.from('profiles').upsert({
    'id': user.id,
    'username': username,
    'phone': phone,
    'email': email,
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  });

  print('✅ Profile created in database');
  print('📱 Phone saved to profiles: $phone');

  return "Please check your email to confirm your account.";
} else {
  print('⚠️ No user returned yet (email confirmation pending).');
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

  /// Get user phone number from profiles table
  Future<String?> getUserPhone(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('phone')
          .eq('id', userId)
          .single();
      
      final phone = response['phone'] as String?;
      print('📞 Retrieved phone from database: $phone for user: $userId');
      return phone;
    } catch (e) {
      print('❌ Error getting user phone: $e');
      return null;
    }
  }

  /// Sign in with email & password + sends OTP if phone exists
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('👤 User signed in: ${response.user!.id}');
        
        // Get phone from profiles table
        final phone = await getUserPhone(response.user!.id);
        
        if (phone != null && phone.isNotEmpty) {
          print('📲 Sending OTP to: $phone');
          try {
            await _client.auth.signInWithOtp(phone: phone);
            return phone; // Return phone to indicate OTP flow needed
          } catch (e) {
            print('❌ Error sending OTP: $e');
            return "Failed to send OTP. Please try again.";
          }
        } else {
          print('⚠️ No phone number found in profiles table, proceeding to home');
          // No phone number found, proceed directly to home
          state = state.copyWith(isAuthenticated: true, user: response.user);
          return null; // success - no OTP needed
        }
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
    final response = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'tamubot://auth/callback',
    );

    // CHANGE THIS LINE ONLY:
    return null; 
    
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}
Future<String?> sendOtpToPhone(String phone) async {
  try {
    await _client.auth.signInWithOtp(phone: phone);
    return "OTP sent successfully";
  } catch (e) {
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
  } catch (e) {
    return e.toString();
  }
}
/// Update user phone number in profiles table
  Future<String?> updateUserPhone(String phone) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return "No user logged in";
      
      await _client.from('profiles').upsert({
        'id': user.id,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Phone updated in profiles: $phone');
      return null; // success
    } catch (e) {
      print('❌ Error updating phone: $e');
      return e.toString();
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Debug method to check user data
  void debugUserData() {
    final user = _client.auth.currentUser;
    print('=== USER DEBUG INFO ===');
    print('User ID: ${user?.id}');
    print('Email: ${user?.email}');
    print('Metadata: ${user?.userMetadata}');
    print('Confirmed: ${user?.emailConfirmedAt}');
    
    if (user != null) {
      _client.from('profiles')
          .select()
          .eq('id', user.id)
          .single()
          .then((profile) {
        print('📊 Profile data: $profile');
      }).catchError((e) {
        print('❌ Error fetching profile: $e');
      });
    }
    print('=====================');
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _client.auth.signOut();
    state = AuthState(isAuthenticated: false);
  }

  /// Change password
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

 /// Forgot password (send reset email)
Future<String?> sendPasswordReset(String email) async {
  try {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'tamubot://auth/callback', // Change this
    );
    return "Password reset email sent! Check your email for the reset link.";
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}}

/// Provider for the AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final client = Supabase.instance.client;
  return AuthController(client);
});