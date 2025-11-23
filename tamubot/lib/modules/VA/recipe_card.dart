// lib/widgets/recipe_card.dart

import 'package:flutter/material.dart';
import 'package:tamubot/modules/VA/assistant_model.dart';

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            if (recipe.ingredients.isNotEmpty) ...[
              const Text(
                'Ingredients:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...recipe.ingredients.map((ingredient) => Text('• $ingredient')),
              const SizedBox(height: 8),
            ],
            
            const Text(
              'Instructions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(recipe.fullRecipe),
          ],
        ),
      ),
    );
  }
}