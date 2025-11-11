import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Local imports
import 'package:tamubot/modules/profile/profile_page.dart';
import 'package:tamubot/modules/recipes/recipes_page.dart';
import 'package:tamubot/modules/settings/settings_page.dart';
import 'package:tamubot/widgets/bottom_nav.dart';
import 'package:tamubot/widgets/voice_assistant_widget.dart';
import '../../providers/navigation_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    // Define the pages for each tab
    final pages = [
      const HomeContent(), // This is the Home tab
      const ProfilePage(),
      const MyRecipesPage(),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Welcome to TamuBot tst 2!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            // Voice assistant widget integrated into Home tab
            VoiceAssistantWidget(),
          ],
        ),
      ),
    );
  }
}
