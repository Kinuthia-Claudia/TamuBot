import 'package:supabase_flutter/supabase_flutter.dart';

class MetricsService {
  final SupabaseClient _supabase = Supabase.instance.client;
    

  // Add this getter to access Supabase client from other files
  SupabaseClient get supabase => _supabase;

  // Add this method to test connection and print detailed info
  Future<void> debugDatabaseConnection() async {
    try {
      print('=== DATABASE DEBUG INFO ===');
      
      // Test if we can connect to Supabase
      print('Supabase client initialized: ${_supabase != null}');
      
      // Test profiles table
      final profiles = await _supabase.from('profiles').select().limit(5);
      print('Profiles table accessible: ${profiles.isNotEmpty}');
      print('Number of profiles: ${profiles.length}');
      if (profiles.isNotEmpty) {
        print('Sample profile data:');
        for (var profile in profiles) {
          print('  - ID: ${profile['id']}, Email: ${profile['email']}, Username: ${profile['username']}');
        }
      } else {
        print('No profiles found in database');
      }
      
      // Test user_recipes table
      final recipes = await _supabase.from('user_recipes').select().limit(5);
      print('Recipes table accessible: ${recipes.isNotEmpty}');
      print('Number of recipes: ${recipes.length}');
      if (recipes.isNotEmpty) {
        print('Sample recipe: ${recipes.first}');
      }
      
      // Test meal_plans table
      final mealPlans = await _supabase.from('meal_plans').select().limit(5);
      print('Meal plans table accessible: ${mealPlans.isNotEmpty}');
      print('Number of meal plans: ${mealPlans.length}');
      if (mealPlans.isNotEmpty) {
        print('Sample meal plan: ${mealPlans.first}');
      }
      
      // Test recipe_interactions table
      final interactions = await _supabase.from('recipe_interactions').select().limit(5);
      print('Interactions table accessible: ${interactions.isNotEmpty}');
      print('Number of interactions: ${interactions.length}');
      if (interactions.isNotEmpty) {
        print('Sample interaction: ${interactions.first}');
      }
      
      print('=== END DEBUG INFO ===');
    } catch (e) {
      print('Database connection error: $e');
      print('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('Postgrest error details: ${e.message}');
      }
    }
  }

  // User Metrics
  Future<int> getTotalUsers() async {
    try {
      final response = await _supabase.from('profiles').select();
      print('Total users query result: ${response.length}');
      return response.length;
    } catch (e) {
      print('Error in getTotalUsers: $e');
      return 0;
    }
  }

  Future<int> getActiveUsersToday() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final response = await _supabase
          .from('recipe_interactions')
          .select('user_id')
          .gte('created_at', startOfDay.toIso8601String());
      
      print('Active users today query result: ${response.length}');
      
      // Get unique users
      final uniqueUsers = <String>{};
      for (final item in response) {
        uniqueUsers.add(item['user_id'].toString());
      }
      return uniqueUsers.length;
    } catch (e) {
      print('Error in getActiveUsersToday: $e');
      return 0;
    }
  }

  // Recipe Metrics
  Future<int> getTotalRecipes() async {
    try {
      final response = await _supabase.from('user_recipes').select();
      print('Total recipes query result: ${response.length}');
      return response.length;
    } catch (e) {
      print('Error in getTotalRecipes: $e');
      return 0;
    }
  }

  Future<int> getTotalMealPlans() async {
    try {
      final response = await _supabase.from('meal_plans').select();
      print('Total meal plans query result: ${response.length}');
      return response.length;
    } catch (e) {
      print('Error in getTotalMealPlans: $e');
      return 0;
    }
  }

  // Recipe Interactions
  Future<List<Map<String, dynamic>>> getTopRatedRecipes() async {
    try {
      final response = await _supabase
          .from('recipe_interactions')
          .select('recipe_id, rating_value')
          .eq('interaction_type', 'rating')
          .order('rating_value', ascending: false)
          .limit(5);

      print('Top rated recipes query result: ${response.length}');
      return response;
    } catch (e) {
      print('Error in getTopRatedRecipes: $e');
      return [];
    }
  }

  // Recent Users
  Future<List<Map<String, dynamic>>> getRecentUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, username, email, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      print('Recent users query result: ${response.length}');
      if (response.isNotEmpty) {
        print('First user: ${response.first}');
      }
      return response;
    } catch (e) {
      print('Error in getRecentUsers: $e');
      return [];
    }
  }

  // Get user registration by month for charts
  Future<List<Map<String, dynamic>>> getUserRegistrationByMonth() async {
    try {
      final response = await _supabase.from('profiles').select('created_at');
      print('User growth data query result: ${response.length}');

      final data = response;
      
      // Group by month
      final Map<String, int> monthlyCount = {};
      
      for (final user in data) {
        try {
          final date = DateTime.parse(user['created_at']).toLocal();
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthlyCount[monthKey] = (monthlyCount[monthKey] ?? 0) + 1;
        } catch (e) {
          print('Error parsing date: ${user['created_at']}');
        }
      }

      // Convert to list and sort by date
      final monthlyList = monthlyCount.entries.map((entry) {
        return {
          'month': entry.key,
          'users': entry.value,
        };
      }).toList();

      monthlyList.sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
      
      print('Monthly user growth data: $monthlyList');
      return monthlyList;
    } catch (e) {
      print('Error in getUserRegistrationByMonth: $e');
      return [];
    }
  }

  // Get total interactions count
  Future<int> getTotalInteractions() async {
    try {
      final response = await _supabase.from('recipe_interactions').select();
      print('Total interactions query result: ${response.length}');
      return response.length;
    } catch (e) {
      print('Error in getTotalInteractions: $e');
      return 0;
    }
  }

  // Get average recipe rating
  Future<double> getAverageRecipeRating() async {
    try {
      final response = await _supabase
          .from('recipe_interactions')
          .select('rating_value')
          .eq('interaction_type', 'rating');

      print('Average rating query result: ${response.length} ratings found');

      if (response.isEmpty) return 0.0;

      final ratings = response
          .where((r) => r['rating_value'] != null)
          .map((r) => (r['rating_value'] as num).toDouble())
          .toList();
      
      if (ratings.isEmpty) return 0.0;
      
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      final result = double.parse(average.toStringAsFixed(1));
      print('Average rating calculated: $result');
      return result;
    } catch (e) {
      print('Error in getAverageRecipeRating: $e');
      return 0.0;
    }
  }
}