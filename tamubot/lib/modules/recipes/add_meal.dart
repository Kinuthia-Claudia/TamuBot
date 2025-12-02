import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/recipes/myrecipes_provider.dart';

class AddMealDialog extends StatefulWidget {
  final String? initialMealType;
  final Function(String, String, String) onRecipeSelected;

  const AddMealDialog({
    super.key,
    this.initialMealType,
    required this.onRecipeSelected,
  });

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  String? _selectedMealType;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? 'lunch';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 500,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Meal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Meal Type Selection
              DropdownButtonFormField<String>(
                value: _selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'breakfast', child: Text('Breakfast')),
                  DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                  DropdownMenuItem(value: 'snack', child: Text('Snack')),
                  DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMealType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Search Recipes
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Saved Recipes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Recipe List
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final recipesAsync = ref.watch(recipesProvider);
                    
                    return recipesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Error loading recipes: $error'),
                      ),
                      data: (recipes) {
                        // Filter recipes based on search
                        final filteredRecipes = _searchQuery.isEmpty
                            ? recipes
                            : recipes.where((recipe) => 
                                recipe.recipeTitle.toLowerCase().contains(_searchQuery.toLowerCase())
                              ).toList();

                        if (filteredRecipes.isEmpty) {
                          return Center(
                            child: Text(
                              _searchQuery.isEmpty 
                                ? 'No saved recipes found'
                                : 'No recipes found for "$_searchQuery"',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = filteredRecipes[index];
                            return ListTile(
                              leading: const Icon(Icons.restaurant),
                              title: Text(recipe.recipeTitle),
                              subtitle: recipe.userRating != null 
                                  ? Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: Colors.amber),
                                        Text(' ${recipe.userRating}'),
                                      ],
                                    )
                                  : null,
                              onTap: () => _selectRecipe(recipe.id, recipe.recipeTitle),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Cancel Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRecipe(String recipeId, String recipeTitle) {
    if (_selectedMealType != null) {
      widget.onRecipeSelected(recipeId, recipeTitle, _selectedMealType!);
      Navigator.of(context).pop();
    }
  }
}