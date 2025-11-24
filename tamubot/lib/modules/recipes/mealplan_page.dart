// lib/modules/meal_plans/meal_plans_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/recipes/mealplan_detail.dart';
import 'package:tamubot/modules/recipes/mealplan_dialog.dart';
import 'package:tamubot/modules/recipes/mealplan_model.dart';
import 'package:tamubot/modules/recipes/mealplan_provider.dart';

class MealPlansPage extends ConsumerWidget {
  const MealPlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlansAsync = ref.watch(mealPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meal Plans'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Share/Export button could go here
        ],
      ),
      body: mealPlansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading meal plans', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        data: (mealPlans) {
          if (mealPlans.isEmpty) {
            return const _EmptyMealPlansState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mealPlans.length,
            itemBuilder: (context, index) {
              final mealPlan = mealPlans[index];
              return _MealPlanCard(mealPlan: mealPlan);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateMealPlanDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  final MealPlan mealPlan;

  const _MealPlanCard({required this.mealPlan});

  @override
  Widget build(BuildContext context) {
    final dayNames = ['M', 'T', 'W', 'Th', 'F', 'Sa', 'Su'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.restaurant_menu, color: Colors.blue.shade700),
        ),
        title: Text(
          mealPlan.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${mealPlan.selectedDays.length} days • ${_countTotalMeals(mealPlan)} meals',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: mealPlan.selectedDays.map((dayIndex) {
                return Chip(
                  label: Text(dayNames[dayIndex]),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
        Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MealPlanDetailPage(mealPlanId: mealPlan.id),
  ),
);
        },
      ),
    );
  }

  int _countTotalMeals(MealPlan plan) {
    int total = 0;
    plan.dailyMeals.forEach((day, meals) {
      total += meals.length;
    });
    return total;
  }
}

class _EmptyMealPlansState extends StatelessWidget {
  const _EmptyMealPlansState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Meal Plans Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first meal plan to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CreateMealPlanDialog(),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Meal Plan'),
          ),
        ],
      ),
    );
  }
}