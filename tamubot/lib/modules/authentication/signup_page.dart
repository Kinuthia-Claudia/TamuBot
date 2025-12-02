import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _error;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Password Validation Helper
  bool _isValidPassword(String password) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'\d').hasMatch(password);
    return hasUpper && hasLower && hasNumber;
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // HEADER
              Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join us and start your journey",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 35),

              // FORM CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100,
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Username
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        filled: true,
                        fillColor: Colors.green.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        filled: true,
                        fillColor: Colors.green.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        filled: true,
                        fillColor: Colors.green.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // PASSWORD RULES
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: Colors.green.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Password must include:\n• One uppercase letter\n• One lowercase letter\n• One number",
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Error message
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade400),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),

                    const SizedBox(height: 22),

                    // SIGN UP BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () async {
                                final password = _passwordController.text;

                                // Local validation (no logic changed)
                                if (!_isValidPassword(password)) {
                                  setState(() {
                                    _error =
                                        "Password must contain uppercase, lowercase, and a number.";
                                  });
                                  return;
                                }

                                setState(() {
                                  _isLoading = true;
                                  _error = null;
                                });

                                final error = await ref
                                    .read(authControllerProvider.notifier)
                                    .signUp(
                                      _emailController.text,
                                      password,
                                      username:
                                          _usernameController.text.trim(),
                                    );

                                setState(() => _isLoading = false);

                                if (error != null) {
                                  setState(() => _error = error);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Please check your email for confirmation."),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                "Create Account",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Google + Login Redirect
              Center(
                child: Column(
                  children: [
                    Text(
                      "Or continue with",
                      style: TextStyle(color: Colors.green.shade900),
                    ),
                    const SizedBox(height: 12),

                    FloatingActionButton(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        final message = await ref
                            .read(authControllerProvider.notifier)
                            .signInWithGoogle();
                        setState(() => _isLoading = false);

                        if (mounted && message != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                      },
                      child: Image.asset(
                        "assets/google.png",
                        width: 28,
                        height: 28,
                      ),
                    ),

                    const SizedBox(height: 22),

                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, "/login");
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: Colors.green.shade900),
                          children: [
                            TextSpan(
                              text: "Sign In",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}