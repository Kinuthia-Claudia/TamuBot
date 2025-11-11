import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider that listens to Supabase auth state changes in real-time.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.onAuthStateChange.map((data) {
    final session = data.session;
    final user = session?.user;
    return AuthState(
      isAuthenticated: user != null,
      user: user,
    );
  });
});

/// Simple class to represent authentication state
class AuthState {
  final bool isAuthenticated;
  final User? user;

  AuthState({required this.isAuthenticated, this.user});
}
