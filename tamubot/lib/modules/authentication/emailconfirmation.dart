import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailConfirmationHandler extends ConsumerStatefulWidget {
  const EmailConfirmationHandler({super.key});

  @override
  ConsumerState<EmailConfirmationHandler> createState() => _EmailConfirmationHandlerState();
}

class _EmailConfirmationHandlerState extends ConsumerState<EmailConfirmationHandler> {
  bool _isChecking = true;
  String _status = 'Checking your email confirmation...';

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final supabase = Supabase.instance.client;
    
    // Check if user is already authenticated (after email confirmation)
    final currentSession = supabase.auth.currentSession;
    
    if (currentSession != null && currentSession.user?.emailConfirmedAt != null) {
      // User is confirmed and logged in
      _navigateToHome();
      return;
    }

    // Listen for auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        // Email confirmed and user signed in
        _navigateToHome();
      } else if (event == AuthChangeEvent.signedOut) {
        // Still not confirmed
        _showConfirmationRequired();
      }
    });

    // Wait a bit and check again
    await Future.delayed(const Duration(seconds: 3));
    
    final updatedSession = supabase.auth.currentSession;
    if (updatedSession != null && updatedSession.user?.emailConfirmedAt != null) {
      _navigateToHome();
    } else {
      _showConfirmationRequired();
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showConfirmationRequired() {
    if (mounted) {
      setState(() {
        _isChecking = false;
        _status = 'Please check your email and click the confirmation link.';
      });
    }
  }

  void _checkAgain() {
    setState(() {
      _isChecking = true;
      _status = 'Checking again...';
    });
    _checkAuthState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Email")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              "Email Confirmation",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _isChecking
                ? const CircularProgressIndicator()
                : const Icon(Icons.hourglass_empty, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            if (!_isChecking) ...[
              ElevatedButton(
                onPressed: _checkAgain,
                child: const Text("Check Again"),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text("Go to Login"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}