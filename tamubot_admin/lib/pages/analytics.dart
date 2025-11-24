import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:tamubot_admin/widgets/metrics.dart';
import 'package:tamubot_admin/widgets/statcard.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final MetricsService _metricsService = MetricsService();
  late Future<Map<String, dynamic>> _analyticsData;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _analyticsData = _loadAnalyticsData();
    _runDebug();
  }

  Future<void> _runDebug() async {
    final output = StringBuffer();
    output.writeln('=== ANALYTICS DEBUG INFO ===');
    
    try {
      // Test each metric individually
      final totalUsers = await _metricsService.getTotalUsers();
      output.writeln('✓ Total Users: $totalUsers');
      
      final totalRecipes = await _metricsService.getTotalRecipes();
      output.writeln('✓ Total Recipes: $totalRecipes');
      
      final totalMealPlans = await _metricsService.getTotalMealPlans();
      output.writeln('✓ Total Meal Plans: $totalMealPlans');
      
      final totalInteractions = await _metricsService.getTotalInteractions();
      output.writeln('✓ Total Interactions: $totalInteractions');
      
      final averageRating = await _debugUserRatings();
      output.writeln('✓ Average User Rating: $averageRating');
      
      final userGrowth = await _metricsService.getUserRegistrationByMonth();
      output.writeln('✓ User Growth Data Points: ${userGrowth.length}');
      
    } catch (e) {
      output.writeln('✗ Error: $e');
    }
    
    setState(() {
      _debugInfo = output.toString();
    });
  }

  // NEW: Debug user ratings to see what's in the table
  Future<double> _debugUserRatings() async {
    try {
      final _supabase = _metricsService.supabase;
      
      // First, let's see what's actually in the user_recipes table
      final allRecipes = await _supabase
          .from('user_recipes')
          .select('id, recipe_title, user_rating, created_at')
          .limit(10);

      print('=== USER_RECIPES TABLE DEBUG ===');
      print('Total recipes in table: ${allRecipes.length}');
      
      for (var recipe in allRecipes) {
        print('Recipe: ${recipe['recipe_title']} | Rating: ${recipe['user_rating']} | ID: ${recipe['id']}');
      }

      // Now get only recipes with ratings
      final response = await _supabase
          .from('user_recipes')
          .select('user_rating')
          .not('user_rating', 'is', null);

      print('=== RATINGS ANALYSIS ===');
      print('Recipes with ratings: ${response.length}');
      
      if (response.isEmpty) {
        print('⚠️ No recipes have user_rating values');
        return 0.0;
      }

      // Print all ratings to see what we're working with
      final ratings = <double>[];
      for (var item in response) {
        final rating = item['user_rating'];
        if (rating != null) {
          final ratingValue = (rating as num).toDouble();
          ratings.add(ratingValue);
          print('Rating value: $ratingValue');
        }
      }

      print('Valid ratings found: ${ratings.length}');
      print('All ratings: $ratings');
      
      if (ratings.isEmpty) {
        print('⚠️ No valid ratings found after filtering');
        return 0.0;
      }
      
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      final result = double.parse(average.toStringAsFixed(1));
      print('📊 Average Rating Calculated: $result from ${ratings.length} ratings');
      return result;
    } catch (e) {
      print('❌ debugUserRatings Error: $e');
      return 0.0;
    }
  }

  // Get average rating from user_recipes table
  Future<double> _getAverageUserRating() async {
    try {
      final _supabase = _metricsService.supabase;
      
      // Try different query approaches
      final response = await _supabase
          .from('user_recipes')
          .select('user_rating')
          .not('user_rating', 'is', null);

      print('📊 User Recipes Rating Query: ${response.length} non-null ratings found');

      if (response.isEmpty) {
        print('⚠️ No non-null user_rating values found');
        return 0.0;
      }

      final ratings = response
          .map((r) => (r['user_rating'] as num).toDouble())
          .toList();
      
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      final result = double.parse(average.toStringAsFixed(1));
      print('📊 Average User Rating: $result from ${ratings.length} ratings');
      return result;
    } catch (e) {
      print('❌ getAverageUserRating Error: $e');
      // Try alternative query
      return await _getAverageUserRatingAlternative();
    }
  }

  // Alternative method in case the first one fails
  Future<double> _getAverageUserRatingAlternative() async {
    try {
      final _supabase = _metricsService.supabase;
      
      // Get all recipes and filter manually
      final allRecipes = await _supabase
          .from('user_recipes')
          .select('user_rating');

      final ratings = allRecipes
          .where((r) => r['user_rating'] != null)
          .map((r) => (r['user_rating'] as num).toDouble())
          .toList();

      print('📊 Alternative Query: ${ratings.length} ratings found from ${allRecipes.length} total recipes');

      if (ratings.isEmpty) return 0.0;
      
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      print('❌ Alternative rating query also failed: $e');
      return 0.0;
    }
  }

  Future<Map<String, dynamic>> _loadAnalyticsData() async {
    try {
      print('=== LOADING ANALYTICS DATA ===');
      
      final totalUsers = await _metricsService.getTotalUsers();
      print('Total Users loaded: $totalUsers');
      
      final totalRecipes = await _metricsService.getTotalRecipes();
      print('Total Recipes loaded: $totalRecipes');
      
      final totalMealPlans = await _metricsService.getTotalMealPlans();
      print('Total Meal Plans loaded: $totalMealPlans');
      
      final totalInteractions = await _metricsService.getTotalInteractions();
      print('Total Interactions loaded: $totalInteractions');
      
      // Use the new method for user_rating from user_recipes table
      final averageRating = await _getAverageUserRating();
      print('Average User Rating loaded: $averageRating');
      
      final userGrowth = await _metricsService.getUserRegistrationByMonth();
      print('User Growth Data loaded: ${userGrowth.length} points');
      
      final result = {
        'totalUsers': totalUsers,
        'totalRecipes': totalRecipes,
        'totalMealPlans': totalMealPlans,
        'totalInteractions': totalInteractions,
        'averageRating': averageRating,
        'userGrowth': userGrowth,
      };
      
      print('=== ANALYTICS DATA LOADED SUCCESSFULLY ===');
      print('Result: $result');
      
      return result;
    } catch (e) {
      print('=== ERROR LOADING ANALYTICS DATA: $e ===');
      return {
        'totalUsers': 0,
        'totalRecipes': 0,
        'totalMealPlans': 0,
        'totalInteractions': 0,
        'averageRating': 0.0,
        'userGrowth': [],
      };
    }
  }

  void _refreshData() {
    print('Refreshing analytics data...');
    setState(() {
      _analyticsData = _loadAnalyticsData();
      _runDebug();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: [
                    // Debug button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bug_report, size: 20, color: Colors.blue),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Analytics Debug Info'),
                            content: SingleChildScrollView(
                              child: SelectableText(_debugInfo),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Debug Info',
                    ),
                    // Refresh button
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.refresh, size: 20),
                      ),
                      onPressed: _refreshData,
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _analyticsData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading analytics data...'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading analytics:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(color: Colors.red[700]),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Stats Cards
                        _buildStatsGrid(data),
                        const SizedBox(height: 32),
                        
                        // User Growth Chart
                        _buildUserGrowthChart(data['userGrowth']),
                        
                        // Additional info about ratings
                        _buildRatingsInfo(data),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> data) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        StatCard(
          title: 'Total Users',
          value: data['totalUsers'].toString(),
          icon: Icons.people_outline,
          color: const Color(0xFF10B981),
        ),
        StatCard(
          title: 'Total Recipes',
          value: data['totalRecipes'].toString(),
          icon: Icons.restaurant_menu,
          color: const Color(0xFF10B981),
        ),
        StatCard(
          title: 'Meal Plans',
          value: data['totalMealPlans'].toString(),
          icon: Icons.calendar_today,
          color: const Color(0xFF059669),
        ),
        StatCard(
          title: 'Interactions',
          value: data['totalInteractions'].toString(),
          icon: Icons.thumb_up,
          color: const Color(0xFF10B981),
        ),
        StatCard(
          title: 'Avg Rating',
          value: data['averageRating'].toString(),
          icon: Icons.star,
          color: const Color(0xFF059669),
        ),
      ],
    );
  }

  Widget _buildRatingsInfo(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['averageRating'] > 0 
              ? 'Average rating is calculated from user_rating values in the user_recipes table.'
              : 'No ratings found. Ratings come from the user_rating column in user_recipes table.',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart(List<Map<String, dynamic>> userGrowth) {
    final chartData = userGrowth.map((data) {
      return _ChartData(data['month'], data['users']);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Registration Growth',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: chartData.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No user growth data available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SfCartesianChart(
                    primaryXAxis: CategoryAxis(),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(text: 'Number of Users'),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries>[
                      ColumnSeries<_ChartData, String>(
                        dataSource: chartData,
                        xValueMapper: (_ChartData data, _) => data.month,
                        yValueMapper: (_ChartData data, _) => data.users,
                        color: const Color(0xFF10B981),
                        dataLabelSettings: const DataLabelSettings(isVisible: true),
                        name: 'User Registrations',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// Helper class for chart data
class _ChartData {
  _ChartData(this.month, this.users);
  final String month;
  final int users;
}