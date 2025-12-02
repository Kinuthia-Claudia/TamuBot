import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/recipes/myrecipes_provider.dart';
import 'package:tamubot/modules/recipes/recipe_service.dart';
import 'package:tamubot/modules/authentication/auth_controller.dart';

class RecipesPage extends ConsumerWidget {
  const RecipesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final user = ref.watch(authControllerProvider).user;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.green.shade50,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline, size: 64, color: Colors.green.shade600),
                const SizedBox(height: 16),
                Text(
                  'Please Sign In',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to view your saved recipes',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('My Recipes'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Recipes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (recipes) {
          if (recipes.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100,
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book, size: 64, color: Colors.green.shade600),
                    const SizedBox(height: 16),
                    Text(
                      'No Saved Recipes Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your saved recipes will appear here',
                      style: TextStyle(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _ExpandableRecipeCard(recipe: recipe);
            },
          );
        },
      ),
    );
  }
}

class _ExpandableRecipeCard extends ConsumerStatefulWidget {
  final SavedRecipe recipe;

  const _ExpandableRecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  ConsumerState<_ExpandableRecipeCard> createState() => _ExpandableRecipeCardState();
}

class _ExpandableRecipeCardState extends ConsumerState<_ExpandableRecipeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ExpansionTile(
        key: Key(recipe.id),
        initiallyExpanded: false,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        title: Text(
          recipe.recipeTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildRecipeSubtitle(recipe),
        trailing: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.green.shade600,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildExpandedContent(recipe),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSubtitle(SavedRecipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recipe.userRating != null) _buildRatingStars(recipe.userRating!),
        const SizedBox(height: 4),
        Text(
          'Saved ${_formatDate(recipe.createdAt)}',
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(SavedRecipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nutrition Information
        if (recipe.recipeData.nutrition.isNotEmpty) 
          _buildNutritionSection(recipe.recipeData.nutrition),
        
        const SizedBox(height: 16),
        
        // Ingredients Section
        _buildSectionTitle('Ingredients'),
        const SizedBox(height: 8),
        ...recipe.recipeData.ingredients.map((ingredient) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ingredient,
                    style: TextStyle(
                      color: ingredient.contains('(substitute:') ? Colors.orange.shade700 : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Instructions Section
        _buildSectionTitle('Instructions'),
        const SizedBox(height: 8),
        ...recipe.recipeData.instructions.asMap().entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Actions
        _buildRecipeActions(recipe),
      ],
    );
  }

  Widget _buildNutritionSection(Map<String, dynamic> nutrition) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nutrition Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (nutrition['calories_per_serving'] != null)
                _NutritionChip(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '${nutrition['calories_per_serving']} cal/serving',
                ),
              if (nutrition['servings'] != null)
                _NutritionChip(
                  icon: Icons.people,
                  label: 'Servings',
                  value: '${nutrition['servings']}',
                ),
              if (nutrition['total_calories'] != null)
                _NutritionChip(
                  icon: Icons.calculate,
                  label: 'Total Calories',
                  value: '${nutrition['total_calories']} cal',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade800,
      ),
    );
  }

  Widget _buildRecipeActions(SavedRecipe recipe) {
    return Row(
      children: [
        // Rating
        if (recipe.userRating == null)
          SizedBox(
            height: 45,
            child: TextButton.icon(
              icon: Icon(Icons.star_border, color: Colors.green.shade700),
              label: Text(
                'Add Rating',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                _showRatingDialog(context, ref, recipe);
              },
            ),
          ),
        
        const Spacer(),
        
        // Delete
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          onPressed: () {
            _showDeleteDialog(context, ref, recipe);
          },
          tooltip: 'Delete Recipe',
        ),
      ],
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref, SavedRecipe recipe) {
    showDialog(
      context: context,
      builder: (context) => _RatingDialog(recipe: recipe),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, SavedRecipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.green.shade50,
        title: Text(
          'Delete Recipe',
          style: TextStyle(color: Colors.green.shade800),
        ),
        content: Text(
          'Are you sure you want to delete "${recipe.recipeTitle}"?',
          style: TextStyle(color: Colors.green.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.green.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(recipesProvider.notifier).deleteRecipe(recipe.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${recipe.recipeTitle}" deleted'),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'today';
    if (difference.inDays == 1) return 'yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${difference.inDays ~/ 7} weeks ago';
    return '${difference.inDays ~/ 30} months ago';
  }
}

class _NutritionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _NutritionChip({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.green.shade700),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
        ],
      ),
      backgroundColor: Colors.green.shade50,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RatingDialog extends ConsumerStatefulWidget {
  final SavedRecipe recipe;

  const _RatingDialog({Key? key, required this.recipe}) : super(key: key);

  @override
  ConsumerState<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends ConsumerState<_RatingDialog> {
  int _selectedRating = 0;

  void _submitRating() async {
    if (_selectedRating == 0) return;

    try {
      await ref.read(recipesProvider.notifier).updateRating(
        widget.recipe.id,
        _selectedRating,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rating saved!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save rating: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.green.shade50,
      title: Text(
        'Rate Recipe',
        style: TextStyle(color: Colors.green.shade800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.recipe.recipeTitle,
            style: TextStyle(color: Colors.green.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return IconButton(
                icon: Icon(
                  rating <= _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () {
                  setState(() {
                    _selectedRating = rating;
                  });
                },
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.green.shade700),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedRating == 0 ? null : _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Submit Rating',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}