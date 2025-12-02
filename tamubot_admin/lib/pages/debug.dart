import 'package:flutter/material.dart';
import 'package:tamubot_admin/widgets/metrics.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final MetricsService _metricsService = MetricsService();
  String _debugOutput = 'Running debug...';

  @override
  void initState() {
    super.initState();
    _runDebug();
  }

  Future<void> _runDebug() async {
    final output = StringBuffer();
    
    output.writeln('=== STARTING DATABASE DEBUG ===');
    output.writeln('Time: ${DateTime.now()}');
    output.writeln('');

    // Test each method individually
    try {
      await _metricsService.debugDatabaseConnection();
      output.writeln('✓ Database connection test completed');
    } catch (e) {
      output.writeln('✗ Database connection test failed: $e');
    }

    output.writeln('');
    output.writeln('=== INDIVIDUAL METRICS TESTS ===');

    // Test total users
    try {
      final totalUsers = await _metricsService.getTotalUsers();
      output.writeln('✓ Total Users: $totalUsers');
    } catch (e) {
      output.writeln('✗ Total Users failed: $e');
    }

    // Test recent users
    try {
      final recentUsers = await _metricsService.getRecentUsers();
      output.writeln('✓ Recent Users: ${recentUsers.length}');
      for (var user in recentUsers.take(3)) {
        output.writeln('  - ${user['email']} (${user['username']})');
      }
    } catch (e) {
      output.writeln('✗ Recent Users failed: $e');
    }

    // Test recipes
    try {
      final totalRecipes = await _metricsService.getTotalRecipes();
      output.writeln('✓ Total Recipes: $totalRecipes');
    } catch (e) {
      output.writeln('✗ Total Recipes failed: $e');
    }

    // Test meal plans
    try {
      final totalMealPlans = await _metricsService.getTotalMealPlans();
      output.writeln('✓ Total Meal Plans: $totalMealPlans');
    } catch (e) {
      output.writeln('✗ Total Meal Plans failed: $e');
    }

    setState(() {
      _debugOutput = output.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDebug,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          _debugOutput,
          style: const TextStyle(fontFamily: 'Monospace', fontSize: 12),
        ),
      ),
    );
  }
}