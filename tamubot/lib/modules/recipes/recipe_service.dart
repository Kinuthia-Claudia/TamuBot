// lib/modules/recipes/recipe_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tamubot/modules/recipes/recipes_model.dart';

class RecipeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // -----------------------------------
  // RECIPE CRUD OPERATIONS
  // -----------------------------------

  /// Save a recipe to user's collection
  Future<SavedRecipe> saveRecipe({
    required String userId,
    required String recipeTitle,
    required Map<String, dynamic> recipeData,
    List<String> dietaryTags = const [],
    int? servingSize,
    int? caloriesPerServing,
    String? prepTime,
    String? cookTime,
    int? userRating,
  }) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .insert({
            'user_id': userId,
            'recipe_title': recipeTitle,
            'recipe_data': recipeData,
            'dietary_tags': dietaryTags,
            'serving_size': servingSize,
            'calories_per_serving': caloriesPerServing,
            'prep_time': prepTime,
            'cook_time': cookTime,
            'user_rating': userRating,
          })
          .select()
          .single();

      return SavedRecipe.fromMap(response);
    } catch (e) {
      throw Exception('Failed to save recipe: $e');
    }
  }

  /// Get all saved recipes for a user
  Future<List<SavedRecipe>> getSavedRecipes(String userId) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) => SavedRecipe.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  /// Get favorite recipes for a user
  Future<List<SavedRecipe>> getFavoriteRecipes(String userId) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .select()
          .eq('user_id', userId)
          .eq('is_favorite', true)
          .order('created_at', ascending: false);

      return (response as List).map((item) => SavedRecipe.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch favorite recipes: $e');
    }
  }

  /// Update recipe rating
  Future<SavedRecipe> updateRecipeRating({
    required String recipeId,
    required int rating,
  }) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .update({'user_rating': rating})
          .eq('id', recipeId)
          .select()
          .single();

      return SavedRecipe.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  /// Toggle recipe favorite status
  Future<SavedRecipe> toggleFavorite({
    required String recipeId,
    required bool isFavorite,
  }) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .update({'is_favorite': isFavorite})
          .eq('id', recipeId)
          .select()
          .single();

      return SavedRecipe.fromMap(response);
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _supabase
          .from('user_recipes')
          .delete()
          .eq('id', recipeId);
    } catch (e) {
      throw Exception('Failed to delete recipe: $e');
    }
  }

  // -----------------------------------
  // RECIPE INTERACTIONS (Analytics)
  // -----------------------------------

  /// Log recipe interaction for analytics
  Future<void> logInteraction({
    required String userId,
    required String interactionType,
    String? recipeId,
    int? ratingValue,
    Map<String, dynamic> interactionData = const {},
  }) async {
    try {
      await _supabase
          .from('recipe_interactions')
          .insert({
            'user_id': userId,
            'recipe_id': recipeId,
            'interaction_type': interactionType,
            'rating_value': ratingValue,
            'interaction_data': interactionData,
          });
    } catch (e) {
      // Don't throw error for analytics failures
      print('Failed to log interaction: $e');
    }
  }
}