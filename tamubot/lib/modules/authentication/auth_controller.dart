// lib/providers/auth_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot/modules/VA/assistant_provider.dart';
import 'package:tamubot/modules/recipes/myrecipes_provider.dart';

import 'package:tamubot/providers/profile_provider.dart';

/// ---------------- AUTH STATE ----------------
class AuthState {
  final bool isAuthenticated;
  final User? user;

  AuthState({required this.isAuthenticated, this.user});

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

/// ---------------- AUTH CONTROLLER ----------------
class AuthController extends StateNotifier<AuthState> {
  final SupabaseClient _client;
  final Ref ref;

  AuthController(this._client, this.ref)
      : super(AuthState(isAuthenticated: false)) {
    _initializeSession();
    _listenAuth();
  }

  /// Initialize session when app starts
  Future<void> _initializeSession() async {
    final session = _client.auth.currentSession;
    final user = session?.user;

    if (user != null) {
      state = state.copyWith(isAuthenticated: true, user: user);
      await _ensureProfileExists(user);
    }
  }

  /// Listen to auth state changes
  void _listenAuth() {
    _client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      final user = session?.user;

      if (user == null) {
        state = AuthState(isAuthenticated: false);
        
        return;
      }

      state = state.copyWith(isAuthenticated: true, user: user);

      // Ensure the profile exists for every logged-in user
      _ensureProfileExists(user);
    
    });
  }

  /// Ensure user profile exists in database
  Future<void> _ensureProfileExists(User user) async {
    try {
      final existing = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _client.from('profiles').upsert({
          'id': user.id,
          'email': user.email,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ Profile created for user: ${user.id}');
      }
    } catch (e) {
      print('❌ Error ensuring profile exists: $e');
    }
  }

  // ---------------------------------------------------------
  // SIGN UP
  // ---------------------------------------------------------
  Future<String?> signUp(
    String email,
    String password, {
    String? username,
  }) async {
    try {
      print('🚀 Signup attempt for $email');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'tamubot://auth/callback',
      );

      final user = response.user;

      if (user != null) {
        print('✅ User created: ${user.id}');

        await _client.from('profiles').upsert({
          'id': user.id,
          'username': username,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        print('✅ Profile inserted');

    

        return "Please check your email to confirm your account.";
      }

      return "Please check your email to confirm your account.";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ---------------------------------------------------------
  // SIGN IN
  // ---------------------------------------------------------
  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return "Invalid login credentials.";

      state = state.copyWith(isAuthenticated: true, user: user);

    

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ---------------------------------------------------------
  // GOOGLE SIGN-IN
  // ---------------------------------------------------------
  Future<String?> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'tamubot://auth/callback',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // ---------------------------------------------------------
  // GET PROFILE
  // ---------------------------------------------------------
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      return await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (e) {
      print('❌ Error loading profile: $e');
      return null;
    }
  }

  // ---------------------------------------------------------
  // PASSWORD MANAGEMENT
  // ---------------------------------------------------------
  Future<String?> changePassword(String newPassword) async {
    try {
      final response =
          await _client.auth.updateUser(UserAttributes(password: newPassword));

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

  // ---------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------
  Future<void> signOut() async {
    await _client.auth.signOut();
    state = AuthState(isAuthenticated: false);

   
  }

  // ---------------------------------------------------------
  // DEBUG
  // ---------------------------------------------------------
  void debugUserData() {
    final user = _client.auth.currentUser;
    print('======= USER DEBUG =======');
    print('ID: ${user?.id}');
    print('Email: ${user?.email}');
    print('Metadata: ${user?.userMetadata}');
    print('Confirmed: ${user?.emailConfirmedAt}');
    print('===========================');
  }
}

/// ---------------- PROVIDER ----------------
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final client = Supabase.instance.client;
  return AuthController(client, ref);
});