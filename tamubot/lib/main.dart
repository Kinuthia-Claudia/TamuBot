import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

// Local imports
import 'package:tamubot/config/supabase_config.dart';
import 'package:tamubot/modules/authentication/changepass_page.dart';
import 'package:tamubot/modules/authentication/emailconfirmation.dart';
import 'package:tamubot/modules/authentication/forgotpass_page.dart';
import 'package:tamubot/modules/authentication/login_page.dart';
import 'package:tamubot/modules/authentication/otpverification_page.dart';
import 'package:tamubot/modules/authentication/signup_page.dart';
import 'package:tamubot/modules/authentication/splashscreen.dart';
import 'package:tamubot/modules/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await SupabaseConfig.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _listenForDeepLinks();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    final client = Supabase.instance.client;
    
    client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      
      debugPrint('🔐 Auth state changed: $event');
      
      if (event == AuthChangeEvent.passwordRecovery) {
        // Password reset link clicked - navigate to change password
        _navigateToChangePassword();
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        // Regular sign-in - navigate to home
        _navigateToHome();
      } else if (event == AuthChangeEvent.signedOut) {
        // Signed out - navigate to login
        _navigateToLogin();
      }
    });
  }

  void _listenForDeepLinks() {
    final appLinks = AppLinks();

    _sub = appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;
      debugPrint('🔗 Deep link received: $uri');

      try {
        final client = Supabase.instance.client;

        // Restore session from URL (token is in fragment after #)
        await client.auth.getSessionFromUrl(uri);

        if (!mounted) return;

        final type = uri.queryParameters['type'];
        debugPrint('👉 Link type: $type');

        if (type == 'recovery') {
          // Forgot password link - navigate to change password
          _navigateToChangePassword();
        } else {
          // Google sign-in, signup confirm, etc. - navigate to home
          _navigateToHome();
        }
      } catch (e) {
        debugPrint('❌ Error handling deep link: $e');
      }
    }, onError: (err) {
      debugPrint('❌ Deep link stream error: $err');
    });
  }

  void _navigateToChangePassword() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushReplacementNamed('/change-password');
    });
  }

  void _navigateToHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushReplacementNamed('/home');
    });
  }

  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushReplacementNamed('/login');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kenyan Cooking Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: _navigatorKey, // Add this for global navigation
      initialRoute: '/home',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        '/change-password': (_) => const ChangePasswordScreen(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
        '/verify-otp': (_) => const VerifyOtpScreen(),
        '/email-confirmation-handler': (_) => const EmailConfirmationHandler(),
      },
    );
  }
}