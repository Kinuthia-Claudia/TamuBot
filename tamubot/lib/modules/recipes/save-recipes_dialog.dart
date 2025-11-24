// lib/modules/recipes/save_recipe_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/recipes/myrecipes_provider.dart';
import 'package:tamubot/modules/recipes/recipe_service.dart';

class SaveRecipeDialog extends ConsumerStatefulWidget {
  final RecipeData recipeData;

  const SaveRecipeDialog({Key? key, required this.recipeData}) : super(key: key);

  @override
  ConsumerState<SaveRecipeDialog> createState() => _SaveRecipeDialogState();
}

class _SaveRecipeDialogState extends ConsumerState<SaveRecipeDialog> {
  int? _selectedRating;
  bool _isFavorite = false;
  bool _isSaving = false;

  void _saveRecipe() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(recipesProvider.notifier).saveRecipe(
        recipeTitle: widget.recipeData.dish,
        recipeData: widget.recipeData,
        rating: _selectedRating,
        isFavorite: _isFavorite,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.recipeData.dish} saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save recipe: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Recipe'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipeData.dish,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Rate this recipe:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final rating = index + 1;
                return IconButton(
                  icon: Icon(
                    _selectedRating != null && rating <= _selectedRating!
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedRating = _selectedRating == rating ? null : rating;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _isFavorite,
                  onChanged: (value) {
                    setState(() {
                      _isFavorite = value ?? false;
                    });
                  },
                ),
                const Text('Add to favorites'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveRecipe,
          child: _isSaving 
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Recipe'),
        ),
      ],
    );
  }
}