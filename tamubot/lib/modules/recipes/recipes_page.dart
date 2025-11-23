// lib/modules/recipes/recipes_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/recipes/myrecipes_provider.dart';
import 'package:tamubot/modules/recipes/recipes_model.dart';

class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  @override
  void initState() {
    super.initState();
    // Load recipes when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipesProvider.notifier).loadUserRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recipesState = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (recipesState.savedRecipes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(recipesProvider.notifier).loadUserRecipes();
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _buildContent(recipesState),
    );
  }

  Widget _buildContent(RecipesState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(recipesProvider.notifier).loadUserRecipes();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.savedRecipes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No recipes saved yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Generate recipes in the assistant to save them here!',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.savedRecipes.length,
      itemBuilder: (context, index) {
        final recipe = state.savedRecipes[index];
        return _buildRecipeCard(recipe);
      },
    );
  }

  Widget _buildRecipeCard(SavedRecipe recipe) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.recipeTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: recipe.isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () {
                    ref.read(recipesProvider.notifier).toggleFavorite(recipe.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Recipe metadata
            if (recipe.prepTime != null || recipe.cookTime != null)
              Row(
                children: [
                  if (recipe.prepTime != null)
                    _buildMetadataChip('⏱ ${recipe.prepTime}'),
                  if (recipe.cookTime != null)
                    _buildMetadataChip('🍳 ${recipe.cookTime}'),
                  if (recipe.servingSize != null)
                    _buildMetadataChip('👥 ${recipe.servingSize} servings'),
                ],
              ),
            
            const SizedBox(height: 8),
            
            // Dietary tags
            if (recipe.dietaryTags.isNotEmpty)
              Wrap(
                spacing: 8,
                children: recipe.dietaryTags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.green.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                  );
                }).toList(),
              ),
            
            const SizedBox(height: 12),
            
            // Rating
            if (recipe.userRating != null)
              Row(
                children: [
                  const Text('Rating: '),
                  _buildRatingStars(recipe.userRating!),
                ],
              ),
            
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showRecipeDetails(recipe);
                    },
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteDialog(recipe);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  void _showRecipeDetails(SavedRecipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe.recipeTitle),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Add recipe details here
              Text('Full recipe details would go here...'),
              const SizedBox(height: 16),
              
              // Rating section
              const Text('Rate this recipe:'),
              _buildInteractiveRating(recipe),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveRating(SavedRecipe recipe) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < (recipe.userRating ?? 0) ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 30,
          ),
          onPressed: () {
            ref.read(recipesProvider.notifier).updateRecipeRating(
              recipeId: recipe.id,
              rating: index + 1,
            );
            Navigator.pop(context);
          },
        );
      }),
    );
  }

  void _showDeleteDialog(SavedRecipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.recipeTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(recipesProvider.notifier).deleteRecipe(recipe.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}