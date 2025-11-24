// lib/modules/meal_plans/meal_plan_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot/modules/recipes/mealplan_model.dart';

class MealPlanService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create meal plan
  Future<MealPlan> createMealPlan(MealPlan mealPlan) async {
    try {
      final response = await _supabase
          .from('meal_plans')
          .insert({
            'user_id': _supabase.auth.currentUser!.id,
            'name': mealPlan.name,
            'description': mealPlan.description,
            'selected_days': mealPlan.selectedDays,
            'daily_meals': _serializeDailyMeals(mealPlan.dailyMeals),
            'created_at': mealPlan.createdAt.toIso8601String(),
            'updated_at': mealPlan.updatedAt.toIso8601String(),
          })
          .select()
          .single();

      return _mealPlanFromJson(response);
    } catch (e) {
      throw Exception('Failed to create meal plan: $e');
    }
  }

  // Get user's meal plans
  Future<List<MealPlan>> getMealPlans() async {
    try {
      final response = await _supabase
          .from('meal_plans')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('updated_at', ascending: false);

      return (response as List).map((json) => _mealPlanFromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch meal plans: $e');
    }
  }

  // Update meal plan
  Future<MealPlan> updateMealPlan(MealPlan mealPlan) async {
    try {
      final response = await _supabase
          .from('meal_plans')
          .update({
            'name': mealPlan.name,
            'description': mealPlan.description,
            'selected_days': mealPlan.selectedDays,
            'daily_meals': _serializeDailyMeals(mealPlan.dailyMeals),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mealPlan.id)
          .select()
          .single();

      return _mealPlanFromJson(response);
    } catch (e) {
      throw Exception('Failed to update meal plan: $e');
    }
  }

  // Delete meal plan
  Future<void> deleteMealPlan(String mealPlanId) async {
    try {
      await _supabase
          .from('meal_plans')
          .delete()
          .eq('id', mealPlanId);
    } catch (e) {
      throw Exception('Failed to delete meal plan: $e');
    }
  }

  // Add meal to day
  Future<MealPlan> addMealToDay({
    required String mealPlanId,
    required int dayIndex,
    required MealSlot meal,
  }) async {
    final currentPlans = await getMealPlans();
    final plan = currentPlans.firstWhere((p) => p.id == mealPlanId);
    
    final updatedMeals = Map<int, List<MealSlot>>.from(plan.dailyMeals);
    if (!updatedMeals.containsKey(dayIndex)) {
      updatedMeals[dayIndex] = [];
    }
    updatedMeals[dayIndex]!.add(meal);
    
    return updateMealPlan(plan.copyWith(dailyMeals: updatedMeals));
  }

  // Remove meal from day
  Future<MealPlan> removeMealFromDay({
    required String mealPlanId,
    required int dayIndex,
    required String mealId,
  }) async {
    final currentPlans = await getMealPlans();
    final plan = currentPlans.firstWhere((p) => p.id == mealPlanId);
    
    final updatedMeals = Map<int, List<MealSlot>>.from(plan.dailyMeals);
    if (updatedMeals.containsKey(dayIndex)) {
      updatedMeals[dayIndex] = updatedMeals[dayIndex]!
          .where((meal) => meal.id != mealId)
          .toList();
    }
    
    return updateMealPlan(plan.copyWith(dailyMeals: updatedMeals));
  }

  // Helper method to safely parse meal plan from JSON
  MealPlan _mealPlanFromJson(Map<String, dynamic> json) {
    // Safely parse selectedDays
    final selectedDays = (json['selected_days'] as List<dynamic>? ?? [])
        .map((day) => (day as num).toInt())
        .toList();

    // Safely parse dailyMeals
    final dailyMealsJson = json['daily_meals'] as Map<String, dynamic>? ?? {};
    final dailyMeals = <int, List<MealSlot>>{};
    
    dailyMealsJson.forEach((key, value) {
      final dayIndex = int.parse(key);
      final mealsList = (value as List<dynamic>? ?? [])
          .map((mealJson) => MealSlot.fromJson(mealJson as Map<String, dynamic>))
          .toList();
      dailyMeals[dayIndex] = mealsList;
    });

    return MealPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Plan',
      description: json['description'] as String?,
      selectedDays: selectedDays,
      dailyMeals: dailyMeals,
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  // Helper method to serialize daily meals
  Map<String, dynamic> _serializeDailyMeals(Map<int, List<MealSlot>> dailyMeals) {
    final result = <String, dynamic>{};
    dailyMeals.forEach((key, value) {
      result[key.toString()] = value.map((meal) => meal.toJson()).toList();
    });
    return result;
  }
}