import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'assistant_service.dart';
import 'assistant_model.dart';

// Service provider
final assistantServiceProvider = Provider<AssistantService>((ref) {
  return AssistantService();
});

// Main assistant provider
class AssistantNotifier extends StateNotifier<AssistantState> {
  final AssistantService service;
  String _currentSessionId = '';
  
  AssistantNotifier(this.service) : super(const AssistantState());

  // Generate session ID only once per conversation
  String get _sessionId {
    if (_currentSessionId.isEmpty) {
      _currentSessionId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    }
    return _currentSessionId;
  }

  // Send message and identify dish
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = AssistantMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      print('Sending message: $message');
      print('Session ID: $_sessionId');

      // Start with identifying dish and getting ingredients
      final response = await service.identifyDish(
        query: message,
        sessionId: _sessionId,
      );

      print('Identify Dish Success: ${response['success']}');

      if (response['success'] == true) {
        final dishName = response['dish'];
        final ingredients = List<String>.from(response['ingredients'] ?? []);
        final nutrition = response['nutrition'] != null 
            ? NutritionInfo.fromMap(response['nutrition'])
            : null;
        
        // Create or update session
        final session = RecipeSession(
          sessionId: _sessionId,
          dishName: dishName,
          ingredients: ingredients,
          nutrition: nutrition,
        );

        // Add assistant response with ingredients
        final assistantMessage = AssistantMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response['message'] ?? "Here are the ingredients for $dishName",
          isUser: false,
          timestamp: DateTime.now(),
          ingredients: ingredients,
          nutrition: nutrition,
        );

        state = state.copyWith(
          messages: [...state.messages, assistantMessage],
          isLoading: false,
          recipeSession: session,
        );

      } else {
        throw Exception(response['error'] ?? 'Failed to identify dish');
      }
    } catch (e) {
      print('Send Message Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to process request: $e',
      );
    }
  }

  // Get cooking instructions
  Future<void> getCookingInstructions() async {
    final session = state.recipeSession;
    if (session == null) {
      state = state.copyWith(error: 'No active recipe session. Please identify a dish first.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('Getting instructions for session: ${session.sessionId}');
      print('Using session ID: $_sessionId');
      
      final response = await service.getInstructions(sessionId: _sessionId);

      print('Get Instructions Success: ${response['success']}');

      if (response['success'] == true) {
        final instructions = List<String>.from(response['instructions'] ?? []);
        final nutrition = response['nutrition'] != null 
            ? NutritionInfo.fromMap(response['nutrition'])
            : null;
        
        // Update session with instructions
        final updatedSession = session.copyWith(
          instructions: instructions,
          nutrition: nutrition ?? session.nutrition,
        );
        
        // Add instructions message
        final instructionsMessage = AssistantMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response['message'] ?? "Here's how to make ${session.dishName}",
          isUser: false,
          timestamp: DateTime.now(),
          instructions: instructions,
          nutrition: nutrition ?? session.nutrition,
        );

        state = state.copyWith(
          messages: [...state.messages, instructionsMessage],
          isLoading: false,
          recipeSession: updatedSession,
        );

      } else {
        throw Exception(response['error'] ?? 'Failed to generate instructions');
      }
    } catch (e) {
      print('Get Instructions Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get instructions: $e',
      );
    }
  }

  // Substitute ingredient (without auto-generating instructions)
  Future<void> substituteIngredient(String ingredient) async {
    final session = state.recipeSession;
    if (session == null) {
      state = state.copyWith(error: 'No active recipe session. Please identify a dish first.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('Substituting ingredient: $ingredient');
      print('Using session ID: $_sessionId');
      
      final response = await service.substituteIngredient(
        sessionId: _sessionId,
        ingredient: ingredient,
      );

      print('Substitute Success: ${response['success']}');

      if (response['success'] == true) {
        final updatedIngredients = List<String>.from(response['updated_ingredients'] ?? []);
        final nutrition = response['nutrition'] != null 
            ? NutritionInfo.fromMap(response['nutrition'])
            : null;
        
        // Update session - clear instructions since ingredients changed
        final updatedSession = session.copyWith(
          ingredients: updatedIngredients,
          instructions: null, // Clear instructions
          nutrition: nutrition ?? session.nutrition,
        );

        // Add substitution message
        final substitutionMessage = AssistantMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response['message'] ?? "Ingredient substituted successfully. Click 'Get Cooking Instructions' to update the recipe.",
          isUser: false,
          timestamp: DateTime.now(),
          ingredients: updatedIngredients,
          nutrition: nutrition ?? session.nutrition,
        );

        state = state.copyWith(
          messages: [...state.messages, substitutionMessage],
          isLoading: false,
          recipeSession: updatedSession,
        );

      } else {
        throw Exception(response['error'] ?? 'Failed to substitute ingredient');
      }
    } catch (e) {
      print('Substitute Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to substitute ingredient: $e',
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear conversation - also reset session ID
  void clearConversation() {
    _currentSessionId = '';
    state = const AssistantState();
  }

  // Debug method to print current session info
  void debugSession() {
    print('Current Session ID: $_currentSessionId');
    print('State Session: ${state.recipeSession?.sessionId}');
    print('State Dish: ${state.recipeSession?.dishName}');
    print('State Has Instructions: ${state.recipeSession?.instructions != null}');
    print('State Nutrition: ${state.recipeSession?.nutrition?.caloriesPerServing} cal/serving');
  }
}

final assistantProvider = StateNotifierProvider<AssistantNotifier, AssistantState>((ref) {
  final service = ref.watch(assistantServiceProvider);
  return AssistantNotifier(service);
});