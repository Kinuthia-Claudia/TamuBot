// lib/modules/recipes/recipe_models.dart

class SavedRecipe {
  final String id;
  final String userId;
  final String recipeTitle;
  final Map<String, dynamic> recipeData;
  final List<String> dietaryTags;
  final int? servingSize;
  final int? caloriesPerServing;
  final String? prepTime;
  final String? cookTime;
  final int? userRating;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavedRecipe({
    required this.id,
    required this.userId,
    required this.recipeTitle,
    required this.recipeData,
    this.dietaryTags = const [],
    this.servingSize,
    this.caloriesPerServing,
    this.prepTime,
    this.cookTime,
    this.userRating,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedRecipe.fromMap(Map<String, dynamic> map) {
    return SavedRecipe(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      recipeTitle: map['recipe_title'] ?? '',
      recipeData: Map<String, dynamic>.from(map['recipe_data'] ?? {}),
      dietaryTags: List<String>.from(map['dietary_tags'] ?? []),
      servingSize: map['serving_size']?.toInt(),
      caloriesPerServing: map['calories_per_serving']?.toInt(),
      prepTime: map['prep_time'],
      cookTime: map['cook_time'],
      userRating: map['user_rating']?.toInt(),
      isFavorite: map['is_favorite'] ?? false,
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'recipe_title': recipeTitle,
      'recipe_data': recipeData,
      'dietary_tags': dietaryTags,
      'serving_size': servingSize,
      'calories_per_serving': caloriesPerServing,
      'prep_time': prepTime,
      'cook_time': cookTime,
      'user_rating': userRating,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SavedRecipe copyWith({
    String? id,
    String? userId,
    String? recipeTitle,
    Map<String, dynamic>? recipeData,
    List<String>? dietaryTags,
    int? servingSize,
    int? caloriesPerServing,
    String? prepTime,
    String? cookTime,
    int? userRating,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedRecipe(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      recipeData: recipeData ?? this.recipeData,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      servingSize: servingSize ?? this.servingSize,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      userRating: userRating ?? this.userRating,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RecipeInteraction {
  final String id;
  final String userId;
  final String? recipeId;
  final String interactionType; // 'viewed', 'saved', 'rated', 'cooked', 'shared'
  final int? ratingValue;
  final Map<String, dynamic> interactionData;
  final DateTime createdAt;

  RecipeInteraction({
    required this.id,
    required this.userId,
    this.recipeId,
    required this.interactionType,
    this.ratingValue,
    this.interactionData = const {},
    required this.createdAt,
  });

  factory RecipeInteraction.fromMap(Map<String, dynamic> map) {
    return RecipeInteraction(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      recipeId: map['recipe_id'],
      interactionType: map['interaction_type'] ?? '',
      ratingValue: map['rating_value']?.toInt(),
      interactionData: Map<String, dynamic>.from(map['interaction_data'] ?? {}),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RecipesState {
  final List<SavedRecipe> savedRecipes;
  final List<SavedRecipe> favoriteRecipes;
  final bool isLoading;
  final String? error;

  const RecipesState({
    this.savedRecipes = const [],
    this.favoriteRecipes = const [],
    this.isLoading = false,
    this.error,
  });

  RecipesState copyWith({
    List<SavedRecipe>? savedRecipes,
    List<SavedRecipe>? favoriteRecipes,
    bool? isLoading,
    String? error,
  }) {
    return RecipesState(
      savedRecipes: savedRecipes ?? this.savedRecipes,
      favoriteRecipes: favoriteRecipes ?? this.favoriteRecipes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}