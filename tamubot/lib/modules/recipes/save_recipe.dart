// lib/widgets/save_recipe_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/VA/assistant_model.dart';

class SaveRecipeDialog extends StatefulWidget {
  final CompleteRecipe recipe;
  final Function(int? rating) onSave;
  final Function() onSkip;

  const SaveRecipeDialog({
    super.key,
    required this.recipe,
    required this.onSave,
    required this.onSkip,
  });

  @override
  State<SaveRecipeDialog> createState() => _SaveRecipeDialogState();
}

class _SaveRecipeDialogState extends State<SaveRecipeDialog> {
  int? _selectedRating;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Recipe?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Would you like to save "${widget.recipe.proposal.title}" to your recipe collection?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          
          const Text(
            'Rate this recipe:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < (_selectedRating ?? 0) 
                      ? Icons.star 
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 8),
          
          if (_selectedRating != null)
            Text(
              '${_selectedRating!} star${_selectedRating! > 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.amber),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onSkip,
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedRating);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Recipe'),
        ),
      ],
    );
  }
}