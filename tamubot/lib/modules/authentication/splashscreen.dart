import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rive/rive.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashComplete;
  
  const SplashScreen({super.key, required this.onSplashComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showContent = false;
  late RiveAnimationController _blinkController;
  late RiveAnimationController _rotateController;
  late RiveAnimationController _upDownController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeApp();
  }

  void _initializeControllers() {
    _blinkController = SimpleAnimation('blink');
    _rotateController = SimpleAnimation('rotate');
    _upDownController = SimpleAnimation('up-down');
  }

  Future<void> _initializeApp() async {
    // Wait for native splash to disappear
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Fade in content
    setState(() {
      _showContent = true;
    });

    // Start animations sequentially for a longer, more engaging experience
    await _playAnimations();
    
    // Notify main app that splash is complete
    widget.onSplashComplete();
  }

  Future<void> _playAnimations() async {
    // Total animation time: ~5 seconds
    await Future.delayed(const Duration(milliseconds: 500)); // Initial pause
    
    // Start blink animation (repeats automatically if looped in Rive)
    await Future.delayed(const Duration(seconds: 1)); // Show idle
    
    // Add rotate animation
    await Future.delayed(const Duration(seconds: 2)); // Rotate duration
    
    // Add up-down animation
    await Future.delayed(const Duration(seconds: 1)); // Up-down duration
    
    // Final pause before navigation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _rotateController.dispose();
    _upDownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _showContent ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular Rive animation container
              Container(
                width: 400,
                height: 400,
                child: ClipOval(
                  child: _showContent 
                      ? RiveAnimation.asset(
                          'assets/animations/robot.riv',
                          animations: const ['idle', 'blink', 'rotate', 'up-down'],
                          fit: BoxFit.cover,
                        )
                      : const SizedBox(),
                ),
              ),
              const SizedBox(height: 30),
              // Animated loading text
              _LoadingText(showContent: _showContent),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingText extends StatefulWidget {
  final bool showContent;

  const _LoadingText({required this.showContent});

  @override
  State<_LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<_LoadingText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.showContent ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: FadeTransition(
        opacity: _animation,
        child: const Text(
          'Loading...',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}