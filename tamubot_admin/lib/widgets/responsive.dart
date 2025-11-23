import 'package:flutter/material.dart';
import 'package:tamubot_admin/dashboard.dart';

class ResponsiveDashboard extends StatelessWidget {
  const ResponsiveDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Desktop layout
          return const AdminDashboard();
        } else {
          // Mobile layout - you can customize this
          return const AdminDashboard();
        }
      },
    );
  }
}