class AssistantState {
  final List<AssistantMessage> messages;
  final bool isLoading;
  final bool isRecording;
  final String? recordingPath;
  final String? error;
  final RecipeSession? recipeSession;

  const AssistantState({
    this.messages = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.recordingPath,
    this.error,
    this.recipeSession,
  });

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    bool? isLoading,
    bool? isRecording,
    String? recordingPath,
    String? error,
    RecipeSession? recipeSession,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      recordingPath: recordingPath ?? this.recordingPath,
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

  Map<String, dynamic> toMap() {
    return {
      'calories_per_serving': caloriesPerServing,
      'total_calories': totalCalories,
      'servings': servings,
      'reasoning': reasoning,
    };
  }
}

class TtsSettings {
  final bool enabled;
  final double speechRate;
  final double pitch;
  final double volume;

  const TtsSettings({
    this.enabled = true,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
  });

  TtsSettings copyWith({
    bool? enabled,
    double? speechRate,
    double? pitch,
    double? volume,
  }) {
    return TtsSettings(
      enabled: enabled ?? this.enabled,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
    );
  }
}

// Recipe generation stages for tracking progress
enum RecipeGenerationStage {
  initial,
  identifyingDish,
  ingredientsReady,
  generatingInstructions,
  instructionsReady,
  complete,
  error
}

// Recipe proposal model (if you want to expand to multi-stage generation)
class RecipeProposal {
  final String title;
  final String description;
  final List<String> ingredients;
  final NutritionInfo nutrition;
  final String cuisine;
  final String difficulty;
  final String prepTime;
  final String cookTime;

  const RecipeProposal({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.nutrition,
    required this.cuisine,
    required this.difficulty,
    required this.prepTime,
    required this.cookTime,
  });

  factory RecipeProposal.fromMap(Map<String, dynamic> map) {
    return RecipeProposal(
      title: map['title'] ?? 'Unknown Recipe',
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      nutrition: NutritionInfo.fromMap(map['nutrition'] ?? {}),
      cuisine: map['cuisine'] ?? 'International',
      difficulty: map['difficulty'] ?? 'Medium',
      prepTime: map['prep_time'] ?? '15 mins',
      cookTime: map['cook_time'] ?? '30 mins',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'nutrition': nutrition.toMap(),
      'cuisine': cuisine,
      'difficulty': difficulty,
      'prep_time': prepTime,
      'cook_time': cookTime,
    };
  }
}

// Complete recipe model
class CompleteRecipe {
  final String title;
  final List<String> ingredients;
  final List<String> instructions;
  final NutritionInfo nutrition;
  final String prepTime;
  final String cookTime;
  final int servings;
  final List<String> tags;
  final List<IngredientSubstitution> substitutions;

  const CompleteRecipe({
    required this.title,
    required this.ingredients,
    required this.instructions,
    required this.nutrition,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    this.tags = const [],
    this.substitutions = const [],
  });

  factory CompleteRecipe.fromSession(RecipeSession session) {
    return CompleteRecipe(
      title: session.dishName ?? 'Unknown Recipe',
      ingredients: session.ingredients ?? [],
      instructions: session.instructions ?? [],
      nutrition: session.nutrition ?? const NutritionInfo(
        caloriesPerServing: 0,
        totalCalories: 0,
        servings: 1,
        reasoning: '',
      ),
      prepTime: '15 mins', // Default values
      cookTime: '30 mins',
      servings: session.nutrition?.servings ?? 1,
      substitutions: session.substitutions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutrition': nutrition.toMap(),
      'prep_time': prepTime,
      'cook_time': cookTime,
      'servings': servings,
      'tags': tags,
      'substitutions': substitutions.map((sub) => {
        'original': sub.original,
        'substitute': sub.substitute,
      }).toList(),
    };
  }
}

// Audio recording state
class AudioRecordingState {
  final bool isRecording;
  final String? filePath;
  final Duration duration;
  final double? amplitude;

  const AudioRecordingState({
    this.isRecording = false,
    this.filePath,
    this.duration = Duration.zero,
    this.amplitude,
  });

  AudioRecordingState copyWith({
    bool? isRecording,
    String? filePath,
    Duration? duration,
    double? amplitude,
  }) {
    return AudioRecordingState(
      isRecording: isRecording ?? this.isRecording,
      filePath: filePath ?? this.filePath,
      duration: duration ?? this.duration,
      amplitude: amplitude ?? this.amplitude,
    );
  }
}

// User preferences for recipe generation
class UserPreferences {
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final String preferredCuisine;
  final String difficultyLevel;
  final int maxCookingTime; // in minutes
  final int maxCaloriesPerServing;
  final bool preferHealthyOptions;

  const UserPreferences({
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    this.preferredCuisine = 'Any',
    this.difficultyLevel = 'Medium',
    this.maxCookingTime = 60,
    this.maxCaloriesPerServing = 800,
    this.preferHealthyOptions = true,
  });

  UserPreferences copyWith({
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    String? preferredCuisine,
    String? difficultyLevel,
    int? maxCookingTime,
    int? maxCaloriesPerServing,
    bool? preferHealthyOptions,
  }) {
    return UserPreferences(
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergies: allergies ?? this.allergies,
      preferredCuisine: preferredCuisine ?? this.preferredCuisine,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      maxCookingTime: maxCookingTime ?? this.maxCookingTime,
      maxCaloriesPerServing: maxCaloriesPerServing ?? this.maxCaloriesPerServing,
      preferHealthyOptions: preferHealthyOptions ?? this.preferHealthyOptions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dietary_restrictions': dietaryRestrictions,
      'allergies': allergies,
      'preferred_cuisine': preferredCuisine,
      'difficulty_level': difficultyLevel,
      'max_cooking_time': maxCookingTime,
      'max_calories_per_serving': maxCaloriesPerServing,
      'prefer_healthy_options': preferHealthyOptions,
    };
  }
}

// Recipe history item
class RecipeHistoryItem {
  final String id;
  final String dishName;
  final DateTime generatedAt;
  final CompleteRecipe recipe;
  final int? userRating;
  final bool isFavorite;

  const RecipeHistoryItem({
    required this.id,
    required this.dishName,
    required this.generatedAt,
    required this.recipe,
    this.userRating,
    this.isFavorite = false,
  });

  RecipeHistoryItem copyWith({
    String? id,
    String? dishName,
    DateTime? generatedAt,
    CompleteRecipe? recipe,
    int? userRating,
    bool? isFavorite,
  }) {
    return RecipeHistoryItem(
      id: id ?? this.id,
      dishName: dishName ?? this.dishName,
      generatedAt: generatedAt ?? this.generatedAt,
      recipe: recipe ?? this.recipe,
      userRating: userRating ?? this.userRating,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dish_name': dishName,
      'generated_at': generatedAt.toIso8601String(),
      'recipe': recipe.toMap(),
      'user_rating': userRating,
      'is_favorite': isFavorite,
    };
  }
}

// App settings
class AppSettings {
  final bool ttsEnabled;
  final bool autoPlayTts;
  final bool saveRecipeHistory;
  final bool allowDataCollection;
  final String themeMode;
  final String language;

  const AppSettings({
    this.ttsEnabled = true,
    this.autoPlayTts = true,
    this.saveRecipeHistory = true,
    this.allowDataCollection = false,
    this.themeMode = 'system',
    this.language = 'en',
  });

  AppSettings copyWith({
    bool? ttsEnabled,
    bool? autoPlayTts,
    bool? saveRecipeHistory,
    bool? allowDataCollection,
    String? themeMode,
    String? language,
  }) {
    return AppSettings(
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      autoPlayTts: autoPlayTts ?? this.autoPlayTts,
      saveRecipeHistory: saveRecipeHistory ?? this.saveRecipeHistory,
      allowDataCollection: allowDataCollection ?? this.allowDataCollection,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tts_enabled': ttsEnabled,
      'auto_play_tts': autoPlayTts,
      'save_recipe_history': saveRecipeHistory,
      'allow_data_collection': allowDataCollection,
      'theme_mode': themeMode,
      'language': language,
    };
  }
}