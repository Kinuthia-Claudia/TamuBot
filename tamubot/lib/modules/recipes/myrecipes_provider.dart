// lib/modules/recipes/recipes_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tamubot/modules/authentication/auth_controller.dart';
import 'package:tamubot/modules/recipes/recipe_service.dart';

final recipesServiceProvider = Provider<RecipesService>((ref) {
  return RecipesService();
});

class RecipesNotifier extends StateNotifier<AsyncValue<List<SavedRecipe>>> {
  final Ref ref;
  final RecipesService service;
  bool _isDisposed = false;

  RecipesNotifier(this.ref, this.service) : super(const AsyncValue.loading()) {
    loadRecipes();
  }

  @override
  set state(AsyncValue<List<SavedRecipe>> value) {
    if (!_isDisposed) {
      super.state = value;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadRecipes() async {
    if (_isDisposed) return;
    
    state = const AsyncValue.loading();

    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) {
        if (!_isDisposed) {
          state = const AsyncValue.data([]);
        }
        return;
      }

      final recipes = await service.getSavedRecipes(user.id);
      if (!_isDisposed) {
        state = AsyncValue.data(recipes);
      }
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> saveRecipe({
    required String recipeTitle,
    required RecipeData recipeData,
    int? rating,
    bool isFavorite = false,
  }) async {
    if (_isDisposed) return;
    
    try {
      final user = ref.read(authControllerProvider).user;
      if (user == null) throw Exception('User not authenticated');

      await service.saveRecipe(
        userId: user.id,
        recipeTitle: recipeTitle,
        recipeData: recipeData,
        rating: rating,
        isFavorite: isFavorite,
      );

      // Reload recipes
      await loadRecipes();
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateRating(String recipeId, int rating) async {
    if (_isDisposed) return;
    
    try {
      await service.updateRecipeRating(
        recipeId: recipeId,
        rating: rating,
      );
      await loadRecipes();
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    if (_isDisposed) return;
    
    try {
      await service.toggleFavorite(recipeId, isFavorite);
      await loadRecipes();
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    if (_isDisposed) return;
    
    try {
      await service.deleteRecipe(recipeId);
      await loadRecipes();
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void clear() {
    if (!_isDisposed) {
      state = const AsyncValue.data([]);
    }
  }
}

final recipesProvider = StateNotifierProvider<RecipesNotifier, AsyncValue<List<SavedRecipe>>>((ref) {
  final service = ref.watch(recipesServiceProvider);
  return RecipesNotifier(ref, service);
});