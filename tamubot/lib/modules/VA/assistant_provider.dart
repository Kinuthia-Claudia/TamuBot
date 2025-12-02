import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assistant_service.dart';
import 'assistant_model.dart';
import 'tts_service.dart';
import 'audio_recorder_service.dart';

// Service providers
final assistantServiceProvider = Provider<AssistantService>((ref) {
  return AssistantService();
});

final audioRecorderProvider = Provider<AudioRecorderService>((ref) {
  return AudioRecorderService();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

// TTS Settings
final ttsSettingsProvider = StateNotifierProvider<TtsSettingsNotifier, TtsSettings>((ref) {
  return TtsSettingsNotifier();
});

class TtsSettingsNotifier extends StateNotifier<TtsSettings> {
  TtsSettingsNotifier() : super(TtsSettings());

  void setSpeechRate(double rate) {
    state = state.copyWith(speechRate: rate);
  }

  void setPitch(double pitch) {
    state = state.copyWith(pitch: pitch);
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume);
  }

  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }
}

// Main assistant provider
class AssistantNotifier extends StateNotifier<AssistantState> {
  final Ref _ref;
  final AssistantService service;
  final AudioRecorderService audioRecorder;
  final TtsService ttsService;
  String _currentSessionId = '';
  
  AssistantNotifier(this._ref, this.service, this.audioRecorder, this.ttsService)
      : super(const AssistantState());

  // Generate session ID only once per conversation
  String get _sessionId {
    if (_currentSessionId.isEmpty) {
      _currentSessionId = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    }
    return _currentSessionId;
  }

  // Voice recording methods
  Future<void> startRecording() async {
    try {
      await audioRecorder.startRecording();
      state = state.copyWith(
        isRecording: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start recording: $e',
      );
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await audioRecorder.stopRecording();
      state = state.copyWith(
        isRecording: false,
        recordingPath: path,
      );
      return path;
    } catch (e) {
      state = state.copyWith(
        isRecording: false,
        error: 'Failed to stop recording: $e',
      );
      return null;
    }
  }
// Process audio input
Future<void> processAudioInput(File audioFile) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    state = state.copyWith(error: 'User not logged in');
    return;
  }

  state = state.copyWith(
    isLoading: true,
    error: null,
  );

  try {
    print('1. Starting audio upload to Supabase...');
    
    // 1. Upload to Supabase
    final audioUrl = await service.uploadAudioToSupabase(
      audioFile: audioFile,
      userId: user.id,
    );

    print('2. Audio uploaded successfully. URL: $audioUrl');
    print('3. Sending transcription request...');

    // 2. Send for transcription
    final transcription = await service.transcribeAudio(
      audioUrl: audioUrl,
      userId: user.id,
    );

    print('4. Transcription response: $transcription');

    if (transcription['success'] == true) {
      final transcribedText = transcription['text'];
      print('5. Transcribed text: $transcribedText');
      
      // 3. Use transcribed text as message
      if (transcribedText.isNotEmpty) {
        await sendMessage(transcribedText);
      } else {
        throw Exception('No text transcribed from audio');
      }
    } else {
      throw Exception(transcription['error'] ?? 'Transcription failed');
    }
  } catch (e) {
    print('Audio processing error: $e');
    state = state.copyWith(
      isLoading: false,
      error: 'Audio processing failed: $e',
    );
  }
}  
// TTS Methods
// Add these methods to your AssistantProvider class

void setPreloadedState({
  required List<AssistantMessage> messages,
  required RecipeSession recipeSession,
}) {
  state = state.copyWith(
    messages: messages,
    recipeSession: recipeSession,
  );
}

void addMessage(AssistantMessage message) {
  final messages = List<AssistantMessage>.from(state.messages)..add(message);
  state = state.copyWith(messages: messages);
}
  Future<void> speakMessage(AssistantMessage message) async {
    final ttsSettings = _ref.read(ttsSettingsProvider);
    
    if (!ttsSettings.enabled) return;

    String textToSpeak = message.content;
    if (message.ingredients != null) {
      textToSpeak += " Ingredients: ${message.ingredients!.join(', ')}";
    }
    if (message.instructions != null) {
      textToSpeak += " Instructions: ${message.instructions!.join('. ')}";
    }

    await ttsService.speak(
      textToSpeak,
      rate: ttsSettings.speechRate,
      pitch: ttsSettings.pitch,
      volume: ttsSettings.volume,
    );
  }

  Future<void> toggleSpeech(AssistantMessage message) async {
    if (ttsService.isPlaying) {
      await ttsService.stop();
    } else {
      await speakMessage(message);
    }
  }

  Future<void> stopSpeech() async {
    await ttsService.stop();
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

        // Auto-speak the response if TTS is enabled
        await speakMessage(assistantMessage);

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

        // Auto-speak the instructions if TTS is enabled
        await speakMessage(instructionsMessage);

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

        // Auto-speak the substitution message if TTS is enabled
        await speakMessage(substitutionMessage);

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
    ttsService.stop();
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
  final audioRecorder = ref.watch(audioRecorderProvider);
  final ttsService = ref.watch(ttsServiceProvider);
  return AssistantNotifier(ref, service, audioRecorder, ttsService);
});