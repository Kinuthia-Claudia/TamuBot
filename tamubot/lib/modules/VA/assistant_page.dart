import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/VA/assistant_model.dart';
import 'assistant_provider.dart';

class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends ConsumerState<AssistantPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      ref.read(assistantProvider.notifier).sendMessage(message);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _getInstructions() {
    ref.read(assistantProvider.notifier).getCookingInstructions();
  }

  void _substituteIngredient(String ingredient) {
    ref.read(assistantProvider.notifier).substituteIngredient(ingredient);
  }

  void _debugSession() {
    ref.read(assistantProvider.notifier).debugSession();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Assistant'),
        actions: [
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
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(state),
          ),
          if (state.error != null) _buildErrorBanner(state.error!),
          _buildInputSection(state),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AssistantState state) {
    if (state.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Ask me for a recipe!',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Example: "How to make chapati"',
              style: TextStyle(color: Colors.grey),
            ),
          ],
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
        return _buildMessageBubble(message, state);
      },
    );
  }

  Widget _buildMessageBubble(AssistantMessage message, AssistantState state) {
    // Check if this is a duplicate ingredients message
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
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.restaurant_menu, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Card(
                  color: message.isUser
                      ? Colors.blue.shade50
                      : Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.nutrition != null && message.ingredients != null)
                          _buildNutritionHeader(message.nutrition!),
                        // Don't show the message content for assistant responses with ingredients
                        if (message.isUser || message.ingredients == null)
                          Text(message.content),
                        if (message.ingredients != null && !isDuplicateIngredients) 
                          _buildIngredients(message.ingredients!, state, message.nutrition),
                        if (message.instructions != null)
                          _buildInstructions(message.instructions!, message.nutrition),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.person, color: Colors.green),
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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40, // Fixed height for horizontal scroll
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
          // Removed reasoning text
        ],
      ),
    );
  }

  Widget _buildNutritionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.blue.shade800,
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
    // Remove duplicates from ingredients list
    final uniqueIngredients = _removeDuplicates(ingredients);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        color: ingredient.contains('(substitute:') ? Colors.orange : Colors.black,
                      ),
                    ),
                  ),
                  if (_canSubstitute(ingredient) && !ingredient.contains('(substitute:'))
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      onPressed: () => _substituteIngredient(_extractIngredientName(ingredient)),
                      tooltip: 'Substitute ${_extractIngredientName(ingredient)}',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.recipeSession?.instructions == null)
            ElevatedButton(
              onPressed: _getInstructions,
              child: const Text('Get Cooking Instructions'),
            )
          else
            Text(
              'Instructions available below ✓',
              style: TextStyle(color: Colors.green.shade600),
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
    // Remove substitution text if already substituted
    if (ingredient.contains('(substitute:')) {
      return ingredient.split('(substitute:').first.trim();
    }
    // Remove quantities and get the main ingredient name
    final clean = ingredient.replaceAll(RegExp(r'^\d+\s*[/\d\s]*(cup|cups|tsp|tbsp|oz|gram|kg|ml|pound|lb)s?\s*'), '');
    return clean.trim();
  }

  Widget _buildInstructions(List<String> instructions, NutritionInfo? nutrition) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...instructions.map((instruction) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(instruction),
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
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(error, style: const TextStyle(color: Colors.red))),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(assistantProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(AssistantState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Ask for a recipe...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              enabled: !state.isLoading,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          if (!state.isLoading) ...[
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _sendMessage,
            ),
          ],
          if (state.isLoading) ...[
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
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}