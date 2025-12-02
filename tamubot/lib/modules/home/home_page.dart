import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/VA/assistant_page.dart';
import 'package:tamubot/modules/recipes/divider.dart';
import 'package:tamubot/widgets/bottom_nav.dart';
import 'package:tamubot/modules/profile/profile_page.dart';
import 'package:tamubot/modules/settings/settings_page.dart';
import '../../providers/navigation_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    // Define the pages for each tab
    final pages = [
      const HomeContent(), 
      const ProfilePage(),
      const  RecipesDividerPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AssistantPage(), 
      ),
    );
  }
}