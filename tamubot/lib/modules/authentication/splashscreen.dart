import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rive/rive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait a bit for native splash to disappear
    await Future.delayed(const Duration(milliseconds: 100));
    
    setState(() {
      _showContent = true;
    });

    // Then check session and proceed
    await _checkSession();
  }

  Future<void> _checkSession() async {
    // Your existing session check logic
    await Future.delayed(const Duration(seconds: 3)); // Your Rive animation time
    
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _showContent ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular Rive animation - bigger size
              Container(
                width: 400, // Increased from 120 to 200
                height: 400, // Increased from 120 to 200
               
                child: ClipOval(
                  child: _showContent 
                      ? RiveAnimation.asset(
                          'assets/animations/robot.riv',
                          animations: const ['idle', 'blink', 'rotate', 'up-down'],
                          fit: BoxFit.cover, // Changed from 'contain' to 'cover'
                        )
                      : const SizedBox(),
                ),
              ),
              const SizedBox(height: 30), // Increased spacing
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 18, // Slightly larger text
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}