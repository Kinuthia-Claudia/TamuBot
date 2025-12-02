import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot_admin/pages/analytics.dart';
import 'package:tamubot_admin/pages/dashboardhome.dart';
import 'package:tamubot_admin/pages/profile.dart';
import 'package:rive/rive.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabase = Supabase.instance.client;
  int _currentIndex = 0;
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email ?? 'Admin';
      });
    }
  }

  final List<Widget> _pages = [
    const UsersManagement(),
    const AnalyticsPage(),
    const ProfilePage(),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            // Resized Rive logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RiveAnimation.asset(
                  'assets/robot.riv',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tamubot',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: const Color(0xFF10B981).withOpacity(0.1),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Vertical Navigation
          Container(
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildNavItem(0, Icons.people, 'Users'),
                _buildNavItem(1, Icons.analytics, 'Analytics'),
                _buildNavItem(2, Icons.person, 'Profile'),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(12),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.logout, size: 20),
                    ),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF10B981).withOpacity(0.3))
                  : null,
            ),
            child: IconButton(
              icon: Icon(
                icon,
                color: isSelected ? const Color(0xFF10B981) : Colors.grey[600],
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _currentIndex = index;
                });
              },
              tooltip: label,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF10B981) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}