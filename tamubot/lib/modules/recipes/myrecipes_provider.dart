// lib/modules/recipes/recipe_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tamubot/modules/recipes/recipe_service.dart';
import 'package:tamubot/modules/recipes/recipes_model.dart';

/// Recipe service provider
final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService();
});

/// Recipes Notifier
class RecipesNotifier extends StateNotifier<RecipesState> {
  final Ref ref;
  final RecipeService service;

  RecipesNotifier(this.ref, this.service) : super(const RecipesState());

  // -----------------------------------
  // CLEAR STATE (on logout)
  // -----------------------------------
  void clear() {
    state = const RecipesState();
  }

  // -----------------------------------
  // LOAD USER RECIPES
  // -----------------------------------
  Future<void> loadUserRecipes() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final savedRecipes = await service.getSavedRecipes(user.id);
      final favoriteRecipes = await service.getFavoriteRecipes(user.id);

      state = state.copyWith(
        savedRecipes: savedRecipes,
        favoriteRecipes: favoriteRecipes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load recipes: $e',
      );
    }
  }

  // -----------------------------------
  // SAVE RECIPE
  // -----------------------------------
  Future<void> saveRecipe({
    required String recipeTitle,
    required Map<String, dynamic> recipeData,
    List<String> dietaryTags = const [],
    int? servingSize,
    int? caloriesPerServing,
    String? prepTime,
    String? cookTime,
    int? userRating,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final savedRecipe = await service.saveRecipe(
        userId: user.id,
        recipeTitle: recipeTitle,
        recipeData: recipeData,
        dietaryTags: dietaryTags,
        servingSize: servingSize,
        caloriesPerServing: caloriesPerServing,
        prepTime: prepTime,
        cookTime: cookTime,
        userRating: userRating,
      );

      // Log interaction
      await service.logInteraction(
        userId: user.id,
        interactionType: 'saved',
        recipeId: savedRecipe.id,
        interactionData: {'recipe_title': recipeTitle},
      );

      // Reload recipes to include the new one
      await loadUserRecipes();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save recipe: $e',
      );
    }
  }

  // -----------------------------------
  // UPDATE RATING
  // -----------------------------------
  Future<void> updateRecipeRating({
    required String recipeId,
    required int rating,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final updatedRecipe = await service.updateRecipeRating(
        recipeId: recipeId,
        rating: rating,
      );

      // Log interaction
      await service.logInteraction(
        userId: user.id,
        interactionType: 'rated',
        recipeId: recipeId,
        ratingValue: rating,
      );

      // Update local state
      final updatedRecipes = state.savedRecipes.map((recipe) {
        if (recipe.id == recipeId) {
          return recipe.copyWith(userRating: rating);
        }
        return recipe;
      }).toList();

      final updatedFavorites = state.favoriteRecipes.map((recipe) {
        if (recipe.id == recipeId) {
          return recipe.copyWith(userRating: rating);
        }
        return recipe;
      }).toList();

      state = state.copyWith(
        savedRecipes: updatedRecipes,
        favoriteRecipes: updatedFavorites,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to update rating: $e');
    }
  }

  // -----------------------------------
  // TOGGLE FAVORITE
  // -----------------------------------
  Future<void> toggleFavorite(String recipeId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final recipe = state.savedRecipes.firstWhere((r) => r.id == recipeId);
      final newFavoriteStatus = !recipe.isFavorite;

      final updatedRecipe = await service.toggleFavorite(
        recipeId: recipeId,
        isFavorite: newFavoriteStatus,
      );

      // Update local state
      final updatedRecipes = state.savedRecipes.map((r) {
        if (r.id == recipeId) {
          return r.copyWith(isFavorite: newFavoriteStatus);
        }
        return r;
      }).toList();

      final updatedFavorites = newFavoriteStatus
          ? [...state.favoriteRecipes, updatedRecipe]
          : state.favoriteRecipes.where((r) => r.id != recipeId).toList();

      state = state.copyWith(
        savedRecipes: updatedRecipes,
        favoriteRecipes: updatedFavorites,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to toggle favorite: $e');
    }
  }

  // -----------------------------------
  // DELETE RECIPE
  // -----------------------------------
  Future<void> deleteRecipe(String recipeId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await service.deleteRecipe(recipeId);

      // Update local state
      final updatedRecipes = state.savedRecipes.where((r) => r.id != recipeId).toList();
      final updatedFavorites = state.favoriteRecipes.where((r) => r.id != recipeId).toList();

      state = state.copyWith(
        savedRecipes: updatedRecipes,
        favoriteRecipes: updatedFavorites,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete recipe: $e');
    }
  }

  // -----------------------------------
  // CLEAR ERROR
  // -----------------------------------
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Recipes provider that reacts to auth changes
final recipesProvider = StateNotifierProvider<RecipesNotifier, RecipesState>((ref) {
  final service = ref.watch(recipeServiceProvider);
  final notifier = RecipesNotifier(ref, service);

  // Load recipes when provider is initialized and user is authenticated
  final user = Supabase.instance.client.auth.currentUser;
  if (user != null) {
    notifier.loadUserRecipes();
  }

  return notifier;
});