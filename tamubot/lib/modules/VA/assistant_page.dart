import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tamubot/modules/VA/assistant_model.dart';
import 'package:tamubot/modules/VA/assistant_provider.dart';
import 'package:tamubot/modules/VA/tts_service.dart';
import 'package:tamubot/modules/recipes/recipe_service.dart';
import 'package:tamubot/modules/recipes/save-recipes_dialog.dart';

// TTS Settings Provider
final ttsSettingsProvider = StateNotifierProvider<TtsSettingsController, TtsSettingsState>((ref) {
  return TtsSettingsController();
});

class TtsSettingsState {
  final bool enabled;
  final double speechRate;
  final double pitch;
  final double volume;
  final String language;

  const TtsSettingsState({
    this.enabled = true,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.language = 'en-US',
  });

  TtsSettingsState copyWith({
    bool? enabled,
    double? speechRate,
    double? pitch,
    double? volume,
    String? language,
  }) {
    return TtsSettingsState(
      enabled: enabled ?? this.enabled,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      language: language ?? this.language,
    );
  }
}

class TtsSettingsController extends StateNotifier<TtsSettingsState> {
  TtsSettingsController() : super(const TtsSettingsState());

  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  void setSpeechRate(double rate) {
    state = state.copyWith(speechRate: rate);
  }

  void setPitch(double pitch) {
    state = state.copyWith(pitch: pitch);
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }
}

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late RecorderController recorderController;
  bool _hasShownSaveDialog = false;
  Timer? _saveDialogTimer;
  bool _showTtsSettings = false;

  @override
  void initState() {
    super.initState();
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    recorderController.dispose();
    _saveDialogTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      ref.read(assistantProvider.notifier).sendMessage(message);
      _textController.clear();
      FocusScope.of(context).unfocus();
      _resetSaveDialogFlag();
    }
  }

  void _getInstructions() {
    ref.read(assistantProvider.notifier).getCookingInstructions().then((_) {
      _startSaveDialogTimer();
    });
  }

  void _substituteIngredient(String ingredient) {
    ref.read(assistantProvider.notifier).substituteIngredient(ingredient);
  }

  void _debugSession() {
    ref.read(assistantProvider.notifier).debugSession();
  }

  Future<void> _startRecording() async {
    await ref.read(assistantProvider.notifier).startRecording();
  }

  Future<void> _stopRecording() async {
    final path = await ref.read(assistantProvider.notifier).stopRecording();
    if (path != null && mounted) {
      _sendAudioRecording(path);
    }
  }

  void _sendAudioRecording(String recordingPath) {
    final audioFile = File(recordingPath);
    ref.read(assistantProvider.notifier).processAudioInput(audioFile);
    _resetSaveDialogFlag();
  }

  void _toggleTts() {
    ref.read(ttsSettingsProvider.notifier).toggleEnabled();
  }

  void _toggleTtsSettings() {
    setState(() {
      _showTtsSettings = !_showTtsSettings;
    });
  }

  void _stopSpeech() {
    ref.read(assistantProvider.notifier).stopSpeech();
  }

  void _toggleSpeech(AssistantMessage message) {
    ref.read(assistantProvider.notifier).toggleSpeech(message);
  }

  void _showSaveRecipeDialog(RecipeData recipeData) {
    _hasShownSaveDialog = true;
    showDialog(
      context: context,
      builder: (context) => SaveRecipeDialog(recipeData: recipeData),
    ).then((saved) {
      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${recipeData.dish} saved to your recipes!'),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  RecipeData _createRecipeDataFromSession() {
    final state = ref.read(assistantProvider);
    final session = state.recipeSession;
    
    if (session == null) {
      throw Exception('No active recipe session');
    }

    return RecipeData(
      dish: session.dishName ?? 'Unknown Recipe',
      ingredients: session.ingredients ?? [],
      instructions: session.instructions ?? [],
      nutrition: {
        'calories_per_serving': session.nutrition?.caloriesPerServing,
        'servings': session.nutrition?.servings,
        'total_calories': session.nutrition?.totalCalories,
        'reasoning': session.nutrition?.reasoning,
      },
      substitutions: session.substitutions.map((sub) => '${sub.original} → ${sub.substitute}').toList(),
    );
  }

  void _startSaveDialogTimer() {
    _saveDialogTimer?.cancel();
    _saveDialogTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _canSaveRecipe(ref.read(assistantProvider)) && !_hasShownSaveDialog) {
        try {
          final recipeData = _createRecipeDataFromSession();
          _showSaveRecipeDialog(recipeData);
        } catch (e) {
          print('Error creating recipe data: $e');
        }
      }
    });
  }

  void _resetSaveDialogFlag() {
    _hasShownSaveDialog = false;
    _saveDialogTimer?.cancel();
  }

  bool _canSaveRecipe(AssistantState state) {
    final session = state.recipeSession;
    return session != null && 
           session.dishName != null &&
           session.ingredients != null &&
           session.ingredients!.isNotEmpty && 
           session.instructions != null &&
           session.instructions!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);
    final ttsSettings = ref.watch(ttsSettingsProvider);
    final ttsService = ref.watch(ttsServiceProvider);

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('Recipe Assistant'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          // TTS Settings Button
          PopupMenuButton<String>(
            icon: Icon(
              ttsSettings.enabled ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onSelected: (value) {
              if (value == 'toggle') {
                _toggleTts();
              } else if (value == 'settings') {
                _toggleTtsSettings();
              } else if (value == 'stop') {
                _stopSpeech();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      ttsSettings.enabled ? Icons.volume_off : Icons.volume_up,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(ttsSettings.enabled ? 'Disable TTS' : 'Enable TTS'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Text('TTS Settings'),
                  ],
                ),
              ),
              if (ttsService.isPlaying)
                PopupMenuItem(
                  value: 'stop',
                  child: Row(
                    children: [
                      Icon(Icons.stop, color: Colors.red.shade400),
                      const SizedBox(width: 8),
                      const Text('Stop Speech'),
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugSession,
            tooltip: 'Debug Session',
          ),
          if (state.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                ref.read(assistantProvider.notifier).clearConversation();
                _resetSaveDialogFlag();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // TTS Settings Panel
          if (_showTtsSettings) _buildTtsSettingsPanel(ttsSettings),
          
          Expanded(
            child: _buildMessagesList(state, ttsService),
          ),
          if (state.error != null) _buildErrorBanner(state.error!),
          _buildInputSection(state),
        ],
      ),
    );
  }

  Widget _buildTtsSettingsPanel(TtsSettingsState ttsSettings) {
    final controller = ref.read(ttsSettingsProvider.notifier);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Text-to-Speech Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.green.shade600),
                onPressed: _toggleTtsSettings,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Speech Rate
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speech Rate: ${ttsSettings.speechRate.toStringAsFixed(1)}',
                style: TextStyle(color: Colors.green.shade700),
              ),
              Slider(
                value: ttsSettings.speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (value) => controller.setSpeechRate(value),
                activeColor: Colors.green.shade600,
                inactiveColor: Colors.green.shade200,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Pitch
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pitch: ${ttsSettings.pitch.toStringAsFixed(1)}',
                style: TextStyle(color: Colors.green.shade700),
              ),
              Slider(
                value: ttsSettings.pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) => controller.setPitch(value),
                activeColor: Colors.green.shade600,
                inactiveColor: Colors.green.shade200,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Volume
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Volume: ${(ttsSettings.volume * 100).toInt()}%',
                style: TextStyle(color: Colors.green.shade700),
              ),
              Slider(
                value: ttsSettings.volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) => controller.setVolume(value),
                activeColor: Colors.green.shade600,
                inactiveColor: Colors.green.shade200,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AssistantState state, TtsService ttsService) {
    if (state.messages.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade100,
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant, size: 64, color: Colors.green.shade600),
              const SizedBox(height: 16),
              Text(
                'Ask me for a recipe!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Example: "How to make chapati"',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.messages.length && state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final message = state.messages[index];
        return _buildMessageBubble(message, state, ttsService);
      },
    );
  }

  Widget _buildMessageBubble(AssistantMessage message, AssistantState state, TtsService ttsService) {
    bool isDuplicateIngredients = false;
    if (!message.isUser && message.ingredients != null) {
      for (final existingMsg in state.messages) {
        if (existingMsg.id != message.id && 
            !existingMsg.isUser && 
            existingMsg.ingredients != null &&
            _areListsEqual(existingMsg.ingredients!, message.ingredients!)) {
          isDuplicateIngredients = true;
          break;
        }
      }
    }

    if (isDuplicateIngredients) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.restaurant_menu, color: Colors.green.shade700),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.green.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade100,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.nutrition != null && message.ingredients != null)
                          _buildNutritionHeader(message.nutrition!),
                        if (message.isUser || message.ingredients == null)
                          Text(
                            message.content,
                            style: TextStyle(
                              color: Colors.green.shade800,
                            ),
                          ),
                        if (message.ingredients != null && !isDuplicateIngredients) 
                          _buildIngredients(message.ingredients!, state, message.nutrition),
                        if (message.instructions != null)
                          _buildInstructions(message.instructions!, message.nutrition),
                        if (!message.isUser)
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  ttsService.isPlaying ? Icons.stop : Icons.play_arrow,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                              ),
                              onPressed: () => _toggleSpeech(message),
                              tooltip: ttsService.isPlaying ? 'Stop' : 'Play',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.person, color: Colors.green.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionHeader(NutritionInfo nutrition) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildNutritionChip('🍽 ${nutrition.servings} servings'),
            const SizedBox(width: 8),
            _buildNutritionChip('🔥 ${nutrition.caloriesPerServing} cal/serving'),
            const SizedBox(width: 8),
            _buildNutritionChip('📊 ${nutrition.totalCalories} total cal'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  Widget _buildIngredients(List<String> ingredients, AssistantState state, NutritionInfo? nutrition) {
    final uniqueIngredients = _removeDuplicates(ingredients);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingredients:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...uniqueIngredients.map((ingredient) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '• $ingredient',
                      style: TextStyle(
                        color: ingredient.contains('(substitute:') 
                            ? Colors.orange.shade700 
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                  if (_canSubstitute(ingredient) && !ingredient.contains('(substitute:'))
                    IconButton(
                      icon: Icon(Icons.swap_horiz, size: 16, color: Colors.green.shade600),
                      onPressed: () => _substituteIngredient(_extractIngredientName(ingredient)),
                      tooltip: 'Substitute ${_extractIngredientName(ingredient)}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.recipeSession?.instructions == null || state.recipeSession!.instructions!.isEmpty)
            ElevatedButton(
              onPressed: _getInstructions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Get Cooking Instructions',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            Text(
              '✓ Instructions ready below',
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  List<String> _removeDuplicates(List<String> list) {
    final seen = <String>{};
    final result = <String>[];
    for (final item in list) {
      if (!seen.contains(item)) {
        seen.add(item);
        result.add(item);
      }
    }
    return result;
  }

  bool _canSubstitute(String ingredient) {
    final cleanIngredient = _extractIngredientName(ingredient).toLowerCase();
    return cleanIngredient.contains('flour') ||
           cleanIngredient.contains('sugar') ||
           cleanIngredient.contains('oil') ||
           cleanIngredient.contains('milk') ||
           cleanIngredient.contains('butter') ||
           cleanIngredient.contains('egg');
  }

  String _extractIngredientName(String ingredient) {
    if (ingredient.contains('(substitute:')) {
      return ingredient.split('(substitute:').first.trim();
    }
    final clean = ingredient.replaceAll(RegExp(r'^\d+\s*[/\d\s]*(cup|cups|tsp|tbsp|oz|gram|kg|ml|pound|lb)s?\s*'), '');
    return clean.trim();
  }

  Widget _buildInstructions(List<String> instructions, NutritionInfo? nutrition) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...instructions.asMap().entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade400),
            onPressed: () {
              ref.read(assistantProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(AssistantState state) {
    final isRecording = state.isRecording;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade100,
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (!state.isLoading) ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRecording ? Colors.red.shade50 : Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      color: isRecording ? Colors.red.shade400 : Colors.green.shade600,
                    ),
                  ),
                  onPressed: () {
                    if (isRecording) {
                      _stopRecording();
                    } else {
                      _startRecording();
                    }
                  },
                ),
              ],
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Ask for a recipe...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.green.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  enabled: !state.isLoading && !isRecording,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              if (!state.isLoading && !isRecording) ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                  onPressed: _sendMessage,
                ),
              ],
              if (state.isLoading || isRecording) ...[
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}