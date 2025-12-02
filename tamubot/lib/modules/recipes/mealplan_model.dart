class MealPlan {
  final String id;
  final String name;
  final String? description;
  final List<int> selectedDays; // 0=Monday, 6=Sunday
  final Map<int, List<MealSlot>> dailyMeals; // dayIndex -> list of meals
  final DateTime createdAt;
  final DateTime updatedAt;

  MealPlan({
    required this.id,
    required this.name,
    this.description,
    required this.selectedDays,
    required this.dailyMeals,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MealPlan.createNew({
    required String name,
    String? description,
    required List<int> selectedDays,
  }) {
    final now = DateTime.now();
    return MealPlan(
      id: 'mealplan_${now.millisecondsSinceEpoch}',
      name: name,
      description: description,
      selectedDays: selectedDays,
      dailyMeals: {},
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'selectedDays': selectedDays,
      'dailyMeals': dailyMeals.map((key, value) => 
        MapEntry(key.toString(), value.map((e) => e.toJson()).toList())),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    // Safely parse selectedDays
    final selectedDays = (json['selectedDays'] as List<dynamic>? ?? [])
        .map((day) => (day as num).toInt())
        .toList();

    // Safely parse dailyMeals
    final dailyMealsJson = json['dailyMeals'] as Map<String, dynamic>? ?? {};
    final dailyMeals = <int, List<MealSlot>>{};
    
    dailyMealsJson.forEach((key, value) {
      final dayIndex = int.parse(key);
      final mealsList = (value as List<dynamic>? ?? [])
          .map((mealJson) => MealSlot.fromJson(mealJson as Map<String, dynamic>))
          .toList();
      dailyMeals[dayIndex] = mealsList;
    });

    return MealPlan(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Plan',
      description: json['description'] as String?,
      selectedDays: selectedDays,
      dailyMeals: dailyMeals,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  MealPlan copyWith({
    String? name,
    String? description,
    List<int>? selectedDays,
    Map<int, List<MealSlot>>? dailyMeals,
  }) {
    return MealPlan(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      selectedDays: selectedDays ?? this.selectedDays,
      dailyMeals: dailyMeals ?? this.dailyMeals,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class MealSlot {
  final String id;
  final String mealType; // breakfast, lunch, dinner, snack
  final String? recipeId;
  final String? recipeTitle;
  final String? customMeal;
  final bool isCustom;

  MealSlot({
    required this.id,
    required this.mealType,
    this.recipeId,
    this.recipeTitle,
    this.customMeal,
    required this.isCustom,
  });

  factory MealSlot.fromRecipe({
    required String mealType,
    required String recipeId,
    required String recipeTitle,
  }) {
    return MealSlot(
      id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
      mealType: mealType,
      recipeId: recipeId,
      recipeTitle: recipeTitle,
      isCustom: false,
    );
  }

  factory MealSlot.custom({
    required String mealType,
    required String customMeal,
  }) {
    return MealSlot(
      id: 'meal_${DateTime.now().millisecondsSinceEpoch}',
      mealType: mealType,
      customMeal: customMeal,
      isCustom: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mealType': mealType,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'customMeal': customMeal,
      'isCustom': isCustom,
    };
  }

  factory MealSlot.fromJson(Map<String, dynamic> json) {
    return MealSlot(
      id: json['id'] as String? ?? '',
      mealType: json['mealType'] as String? ?? 'lunch',
      recipeId: json['recipeId'] as String?,
      recipeTitle: json['recipeTitle'] as String?,
      customMeal: json['customMeal'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  String get displayName {
    if (isCustom) {
      return customMeal!;
    } else {
      return recipeTitle!;
    }
  }
}