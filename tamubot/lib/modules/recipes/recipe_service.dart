import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeData {
  final String dish;
  final List<String> ingredients;
  final List<String> instructions;
  final Map<String, dynamic> nutrition;
  final List<String>? substitutions;

  RecipeData({
    required this.dish,
    required this.ingredients,
    required this.instructions,
    required this.nutrition,
    this.substitutions,
  });

  Map<String, dynamic> toJson() {
    return {
      'dish': dish,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutrition': nutrition,
      'substitutions': substitutions ?? [],
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory RecipeData.fromJson(Map<String, dynamic> json) {
    return RecipeData(
      dish: json['dish'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      nutrition: Map<String, dynamic>.from(json['nutrition'] ?? {}),
      substitutions: List<String>.from(json['substitutions'] ?? []),
    );
  }
}

class SavedRecipe {
  final String id;
  final String userId;
  final String recipeTitle;
  final RecipeData recipeData;
  final int? userRating;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedRecipe({
    required this.id,
    required this.userId,
    required this.recipeTitle,
    required this.recipeData,
    this.userRating,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedRecipe.fromJson(Map<String, dynamic> json) {
    return SavedRecipe(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      recipeTitle: json['recipe_title'] ?? '',
      recipeData: RecipeData.fromJson(json['recipe_data'] ?? {}),
      userRating: json['user_rating'],
      isFavorite: json['is_favorite'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipe_title': recipeTitle,
      'recipe_data': recipeData.toJson(),
      'user_rating': userRating,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class RecipesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Save recipe with optional rating
  Future<SavedRecipe> saveRecipe({
    required String userId,
    required String recipeTitle,
    required RecipeData recipeData,
    int? rating,
    bool isFavorite = false,
  }) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .insert({
            'user_id': userId,
            'recipe_title': recipeTitle,
            'recipe_data': recipeData.toJson(),
            'user_rating': rating,
            'is_favorite': isFavorite,
          })
          .select()
          .single();

      // Log interaction
      await _logInteraction(
        userId: userId,
        interactionType: 'saved',
        ratingValue: rating,
      );

      return SavedRecipe.fromJson(response);
    } catch (e) {
      throw Exception('Failed to save recipe: $e');
    }
  }

  // Update recipe rating
  Future<SavedRecipe> updateRecipeRating({
    required String recipeId,
    required int rating,
  }) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .update({
            'user_rating': rating,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recipeId)
          .select()
          .single();

      // Log rating interaction
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _logInteraction(
          userId: user.id,
          interactionType: 'rated',
          ratingValue: rating,
          recipeId: recipeId,
        );
      }

      return SavedRecipe.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  // Get user's saved recipes
  Future<List<SavedRecipe>> getSavedRecipes(String userId) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => SavedRecipe.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  // Delete recipe
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

  // Toggle favorite
  Future<SavedRecipe> toggleFavorite(String recipeId, bool isFavorite) async {
    try {
      final response = await _supabase
          .from('user_recipes')
          .update({
            'is_favorite': isFavorite,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recipeId)
          .select()
          .single();

      return SavedRecipe.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update favorite: $e');
    }
  }

  // Log interaction for analytics
  Future<void> _logInteraction({
    required String userId,
    required String interactionType,
    int? ratingValue,
    String? recipeId,
  }) async {
    try {
      await _supabase
          .from('recipe_interactions')
          .insert({
            'user_id': userId,
            'recipe_id': recipeId,
            'interaction_type': interactionType,
            'rating_value': ratingValue,
            'interaction_data': {
              'timestamp': DateTime.now().toIso8601String(),
            },
          });
    } catch (e) {
      // Don't throw error for analytics logging
      print('Failed to log interaction: $e');
    }
  }
}