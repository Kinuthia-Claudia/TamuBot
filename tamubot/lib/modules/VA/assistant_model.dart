class AssistantState {
  final List<AssistantMessage> messages;
  final bool isLoading;
  final String? error;
  final RecipeSession? recipeSession;

  const AssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.recipeSession,
  });

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? isLoading,
    String? error,
    RecipeSession? recipeSession,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      recipeSession: recipeSession ?? this.recipeSession,
    );
  }
}

class AssistantMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? ingredients;
  final List<String>? instructions;
  final NutritionInfo? nutrition;

  AssistantMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.ingredients,
    this.instructions,
    this.nutrition,
  });
}

class RecipeSession {
  final String sessionId;
  final String? dishName;
  final List<String>? ingredients;
  final List<String>? instructions;
  final List<IngredientSubstitution> substitutions;
  final NutritionInfo? nutrition;

  const RecipeSession({
    required this.sessionId,
    this.dishName,
    this.ingredients,
    this.instructions,
    this.substitutions = const [],
    this.nutrition,
  });

  RecipeSession copyWith({
    String? dishName,
    List<String>? ingredients,
    List<String>? instructions,
    List<IngredientSubstitution>? substitutions,
    NutritionInfo? nutrition,
  }) {
    return RecipeSession(
      sessionId: sessionId,
      dishName: dishName ?? this.dishName,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      substitutions: substitutions ?? this.substitutions,
      nutrition: nutrition ?? this.nutrition,
    );
  }
}

class IngredientSubstitution {
  final String original;
  final String substitute;

  IngredientSubstitution({
    required this.original,
    required this.substitute,
  });
}

class NutritionInfo {
  final int caloriesPerServing;
  final int totalCalories;
  final int servings;
  final String reasoning;

  const NutritionInfo({
    required this.caloriesPerServing,
    required this.totalCalories,
    required this.servings,
    required this.reasoning,
  });

  factory NutritionInfo.fromMap(Map<String, dynamic> map) {
    return NutritionInfo(
      caloriesPerServing: (map['calories_per_serving'] ?? 0).toInt(),
      totalCalories: (map['total_calories'] ?? 0).toInt(),
      servings: (map['servings'] ?? 1).toInt(),
      reasoning: map['reasoning'] ?? '',
    );
  }
}