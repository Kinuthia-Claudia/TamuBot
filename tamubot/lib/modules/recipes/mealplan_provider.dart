import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tamubot/modules/recipes/mealplan_model.dart';
import 'package:tamubot/modules/recipes/mealplan_service.dart';

final mealPlanServiceProvider = Provider<MealPlanService>((ref) {
  return MealPlanService();
});

class MealPlanNotifier extends StateNotifier<AsyncValue<List<MealPlan>>> {
  final Ref ref;
  final MealPlanService service;
  bool _isDisposed = false;

  MealPlanNotifier(this.ref, this.service) : super(const AsyncValue.loading()) {
    loadMealPlans();
  }

  @override
  set state(AsyncValue<List<MealPlan>> value) {
    if (!_isDisposed) {
      super.state = value;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadMealPlans() async {
    if (_isDisposed) return;
    
    state = const AsyncValue.loading();

    try {
      final mealPlans = await service.getMealPlans();
      if (!_isDisposed) {
        state = AsyncValue.data(mealPlans);
      }
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> createMealPlan({
    required String name,
    String? description,
    required List<int> selectedDays,
  }) async {
    if (_isDisposed) return;
    
    try {
      final newMealPlan = MealPlan.createNew(
        name: name,
        description: description,
        selectedDays: selectedDays,
      );
      
      await service.createMealPlan(newMealPlan);
      await loadMealPlans(); 
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> updateMealPlan(MealPlan mealPlan) async {
    if (_isDisposed) return;
    
    try {
      await service.updateMealPlan(mealPlan);
      await loadMealPlans(); 
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> deleteMealPlan(String mealPlanId) async {
    if (_isDisposed) return;
    
    try {
      await service.deleteMealPlan(mealPlanId);
      await loadMealPlans(); 
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addMealToDay({
    required String mealPlanId,
    required int dayIndex,
    required MealSlot meal,
  }) async {
    if (_isDisposed) return;
    
    try {
      await service.addMealToDay(
        mealPlanId: mealPlanId,
        dayIndex: dayIndex,
        meal: meal,
      );
      await loadMealPlans(); 
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> removeMealFromDay({
    required String mealPlanId,
    required int dayIndex,
    required String mealId,
  }) async {
    if (_isDisposed) return;
    
    try {
      await service.removeMealFromDay(
        mealPlanId: mealPlanId,
        dayIndex: dayIndex,
        mealId: mealId,
      );
      await loadMealPlans(); 
    } catch (e, st) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void clear() {
    if (!_isDisposed) {
      state = const AsyncValue.data([]);
    }
  }
}

final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, AsyncValue<List<MealPlan>>>((ref) {
  final service = ref.watch(mealPlanServiceProvider);
  return MealPlanNotifier(ref, service);
});