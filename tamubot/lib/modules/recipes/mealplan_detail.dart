// lib/modules/meal_plans/meal_plan_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/recipes/add_meal.dart';
import 'package:tamubot/modules/recipes/mealplan_model.dart';
import 'package:tamubot/modules/recipes/mealplan_provider.dart';
import 'package:tamubot/modules/recipes/pdf_exports.dart';

class MealPlanDetailPage extends ConsumerWidget {
  final String mealPlanId; // Change from MealPlan to mealPlanId

  const MealPlanDetailPage({super.key, required this.mealPlanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlansAsync = ref.watch(mealPlanProvider);
    
    return mealPlansAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (mealPlans) {
        final mealPlan = mealPlans.firstWhere(
          (plan) => plan.id == mealPlanId,
          orElse: () => throw Exception('Meal plan not found'),
        );
        
        return _MealPlanDetailContent(mealPlan: mealPlan);
      },
    );
  }
}

class _MealPlanDetailContent extends ConsumerWidget {
  final MealPlan mealPlan;

  const _MealPlanDetailContent({required this.mealPlan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(mealPlan.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportMealPlan(context, mealPlan),
            tooltip: 'Export Meal Plan',
          ),
        ],
      ),
      body: _buildMealPlanTable(context, ref, mealPlan),
    );
  }

  Widget _buildMealPlanTable(BuildContext context, WidgetRef ref, MealPlan mealPlan) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final mealTypes = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Table(
            border: TableBorder.all(color: Colors.grey[300]!),
            defaultColumnWidth: const FixedColumnWidth(150),
            columnWidths: const {
              0: FixedColumnWidth(100), // Day column
            },
            children: [
              // Header row with meal types
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                ),
                children: [
                  _buildHeaderCell('Day'),
                  ...mealTypes.map((mealType) => _buildHeaderCell(mealType)),
                ],
              ),
              // Data rows for each day
              ...mealPlan.selectedDays.asMap().entries.map((entry) {
                final dayIndex = entry.key;
                final dayNumber = entry.value;
                final dayMeals = mealPlan.dailyMeals[dayNumber] ?? [];
                
                return TableRow(
                  decoration: BoxDecoration(
                    color: dayIndex.isEven ? Colors.grey[50] : Colors.white,
                  ),
                  children: [
                    _buildDayCell(dayNames[dayNumber]),
                    ...mealTypes.map((mealType) => _buildMealCell(
                      context,
                      ref,
                      mealPlan.id, // Pass mealPlanId instead of mealPlan
                      dayNumber,
                      mealType,
                      _findMealForType(dayMeals, mealType),
                    )),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      constraints: const BoxConstraints(minHeight: 60),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.green[900],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDayCell(String dayName) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: Colors.green[100],
      ),
      child: Text(
        dayName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.green[900],
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMealCell(BuildContext context, WidgetRef ref, String mealPlanId, int dayIndex, String mealType, MealSlot? meal) {
    return GestureDetector(
      onTap: () => _addOrReplaceMeal(context, ref, mealPlanId, dayIndex, mealType, meal),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        constraints: const BoxConstraints(minHeight: 80),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          color: meal != null ? Colors.green[50] : Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (meal != null)
              _buildMealContent(meal)
            else
              _buildEmptyMealContent(mealType),
          ],
        ),
      ),
    );
  }

  Widget _buildMealContent(MealSlot meal) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getMealTypeIcon(meal.mealType),
          size: 20,
          color: Colors.green[700],
        ),
        const SizedBox(height: 4),
        Text(
          meal.displayName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Tap to change',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMealContent(String mealType) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getMealTypeIcon(mealType.toLowerCase()),
          size: 20,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to add $mealType',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  MealSlot? _findMealForType(List<MealSlot> meals, String mealType) {
    try {
      return meals.firstWhere(
        (meal) => meal.mealType.toLowerCase() == mealType.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  void _addOrReplaceMeal(BuildContext context, WidgetRef ref, String mealPlanId, int dayIndex, String mealType, MealSlot? existingMeal) {
    showDialog(
      context: context,
      builder: (context) => AddMealDialog(
        initialMealType: mealType.toLowerCase(),
        onRecipeSelected: (recipeId, recipeTitle, selectedMealType) async {
          try {
            // If there's an existing meal of the same type, remove it first
            if (existingMeal != null) {
              await ref.read(mealPlanProvider.notifier).removeMealFromDay(
                mealPlanId: mealPlanId,
                dayIndex: dayIndex,
                mealId: existingMeal.id,
              );
            }
            
            // Add the new meal
            final meal = MealSlot.fromRecipe(
              mealType: selectedMealType,
              recipeId: recipeId,
              recipeTitle: recipeTitle,
            );
            
            await ref.read(mealPlanProvider.notifier).addMealToDay(
              mealPlanId: mealPlanId,
              dayIndex: dayIndex,
              meal: meal,
            );
            
            // Success is handled by the provider's state update
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating meal: $e')),
              );
            }
          }
        },
      ),
    );
  }

  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.local_cafe;
      default:
        return Icons.restaurant;
    }
  }

  void _exportMealPlan(BuildContext context, MealPlan mealPlan) async {
    try {
      await PdfExportService.exportMealPlanToPdf(mealPlan);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting: $e')),
      );
    }
  }
}