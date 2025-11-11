import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

// Local imports
import 'package:tamubot/config/supabase_config.dart';
import 'package:tamubot/modules/authentication/changepass_page.dart';
import 'package:tamubot/modules/authentication/forgotpass_page.dart';
import 'package:tamubot/modules/authentication/login_page.dart';
import 'package:tamubot/modules/authentication/signup_page.dart';
import 'package:tamubot/modules/authentication/splashscreen.dart';
import 'package:tamubot/modules/authentication/otpverification_page.dart';
import 'package:tamubot/modules/home/home_page.dart';
import 'package:tamubot/modules/profile/profile_page.dart';
import 'package:tamubot/modules/settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables and initialize Supabase
  await dotenv.load(fileName: '.env');
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
    _setupAuthListener();
    _listenForDeepLinks();
  }

  /// ✅ Listen for Supabase authentication state changes
  void _setupAuthListener() {
    final client = Supabase.instance.client;

    client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      debugPrint('🔐 Auth state changed: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        _navigateToChangePassword();
      } else if (event == AuthChangeEvent.signedIn && session != null) {
        _navigateToHome();
      } else if (event == AuthChangeEvent.signedOut) {
        _navigateToLogin();
      }
    });
  }

  /// ✅ Listen for magic link or OAuth redirect deep links (via app_links)
  void _listenForDeepLinks() {
    final appLinks = AppLinks();

    _sub = appLinks.uriLinkStream.listen((Uri? uri) async {
      if (uri == null) return;
      debugPrint('🔗 Deep link received: $uri');

      try {
        final client = Supabase.instance.client;

        // ✅ Recover Supabase session from the deep link
        await client.auth.getSessionFromUrl(uri);

        if (!mounted) return;
        _navigateToHome();
      } catch (e) {
        debugPrint('❌ Deep link handling failed: $e');
      }
    }, onError: (err) {
      debugPrint('❌ Deep link stream error: $err');
    });
  }

  /// ✅ Navigation helpers
  void _navigateToChangePassword() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushReplacementNamed('/change-password');
    });
  }

  void _navigateToHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil('/home', (route) => false);
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
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: const Color(0xFFF9F4F1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.brown,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.brown, width: 2),
          ),
        ),
      ),
      navigatorKey: _navigatorKey,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomePage(),
       '/change-password': (_) => const ChangePasswordScreen(),
        '/forgot-password': (_) => const ForgotPasswordPage(), 
        '/magic-link-wait': (_) => const MagicLinkWaitScreen(),
        '/profile': (_) => const ProfilePage(),
        '/settings': (_) => const SettingsPage(),

      },
    );
  }
}
