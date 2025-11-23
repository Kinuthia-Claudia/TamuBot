import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot/modules/authentication/forgotpass_page.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _error;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadRememberMeFlag();
  }

  Future<void> _loadRememberMeFlag() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveRememberMeFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  Future<String?> _showEmailInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter your email"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: "Email",
            hintText: "you@example.com",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
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
                "Welcome Back",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Sign in to continue your journey",
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
                    // Email
                    TextField(
                      controller: _emailController,
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
                      keyboardType: TextInputType.emailAddress,
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

                    // Error
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
                                style:
                                    TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Remember Me + Forgot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() => _rememberMe = val ?? false);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Text(
                              "Remember me",
                              style: TextStyle(
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                  _error = null;
                                });

                                final result = await ref
                                    .read(authControllerProvider.notifier)
                                    .signIn(
                                      _emailController.text,
                                      _passwordController.text,
                                    );

                                setState(() => _isLoading = false);

                                if (result == null) {
                                  if (_rememberMe) {
                                    await _saveRememberMeFlag(true);
                                  }
                                } else if (result is String &&
                                    result.length > 10) {
                                  if (_rememberMe) {
                                    await _saveRememberMeFlag(true);
                                  }
                                  if (mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/verify-otp',
                                      arguments: {'phone': result},
                                    );
                                  }
                                } else {
                                  setState(() => _error = result);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Social + OTP
              Center(
                child: Column(
                  children: [
                    Text(
                      "Or continue with",
                      style: TextStyle(color: Colors.green.shade900),
                    ),
                    const SizedBox(height: 15),

                    // Google + Email OTP Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // GOOGLE
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: FloatingActionButton(
                            backgroundColor: Colors.white,
                            elevation: 2,
                            onPressed: () async {
                              setState(() => _isLoading = true);
                              final message = await ref
                                  .read(authControllerProvider.notifier)
                                  .signInWithGoogle();
                              setState(() => _isLoading = false);

                              if (mounted) {
                                if (message == "SUCCESS") {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text("Google sign-in successful"),
                                  ));
                                } else if (message != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              }
                            },
                            child: Image.asset(
                              "assets/google.png",
                              width: 28,
                              height: 28,
                            ),
                          ),
                        ),

                        const SizedBox(width: 28),

                        // EMAIL OTP
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: FloatingActionButton(
                            backgroundColor: Colors.white,
                            elevation: 2,
                            onPressed: () async {
                              final email =
                                  await _showEmailInputDialog(context);
                              if (email == null || email.isEmpty) return;

                              try {
                                await Supabase.instance.client.auth
                                    .signInWithOtp(
                                  email: email,
                                  emailRedirectTo:
                                      'com.example.tamubot://login-callback',
                                );

                                if (mounted) {
                                  Navigator.pushNamed(
                                    context,
                                    '/magic-link-wait',
                                    arguments: {'email': email},
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Failed to send magic link: $e"),
                                  ),
                                );
                              }
                            },
                            child: const Icon(
                              Icons.email_outlined,
                              color: Colors.green,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // Sign Up Redirect
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.green.shade900),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
    super.dispose();
  }
}
