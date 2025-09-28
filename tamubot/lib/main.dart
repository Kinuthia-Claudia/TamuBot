import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot/config/supabase_config.dart';
import 'package:tamubot/modules/authentication/changepass_page.dart';
import 'package:tamubot/modules/authentication/forgotpass_page.dart';
import 'package:tamubot/modules/authentication/login_page.dart';
import 'package:tamubot/modules/authentication/otpverification_page.dart';
import 'package:tamubot/modules/authentication/phoneentry_page.dart';
import 'package:tamubot/modules/authentication/signup_page.dart';
import 'package:tamubot/modules/home/home_page.dart';

import 'dart:async';
import 'package:uni_links5/uni_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await SupabaseConfig.init();

  // Wrap app with Riverpod ProviderScope
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) async {
      if (uri != null) {
        final client = Supabase.instance.client;
        await client.auth.getSessionFromUrl(uri);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }, onError: (err) {
      debugPrint('Error handling deep link: $err');
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
         '/change-password': (_) => const ChangePasswordPage(),
    '/forgot-password': (_) => const ForgotPasswordPage(),
      '/phone-login': (_) => const PhoneLoginScreen(),
  '/verify-otp': (_) => const VerifyOtpScreen(),
      },
    );
  }
}