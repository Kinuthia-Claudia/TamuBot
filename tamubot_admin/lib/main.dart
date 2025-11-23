import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot_admin/adminwrapper.dart';
import 'package:tamubot_admin/.env';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

 await Supabase.initialize(
    url: Env.SUPABASE_URL,
    anonKey: Env.SUPABASE_ANON_KEY,
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamubot Admin Dashboard',
      theme: ThemeData(
        primaryColor: const Color(0xFF10B981),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF059669),
          background: Colors.white,
        ),
        fontFamily: 'Inter',
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}