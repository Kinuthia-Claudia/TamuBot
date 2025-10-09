import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamubot/modules/authentication/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _recipesFuture;

  @override
  void initState() {
    super.initState();
    _recipesFuture = _fetchRecipes();
  }

  Future<List<Map<String, dynamic>>> _fetchRecipes() async {
    final response = await Supabase.instance.client
        .from('recipes')
        .select()
        .limit(50);
    return response;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("TamuBot Kitchen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Karibu ${authState.user?.email ?? 'Chef'}! 👋",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your Kenyan Cooking Assistant",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Recipes Section
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _recipesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          "Failed to load recipes",
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No recipes found",
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }
                
                final recipes = snapshot.data!;
                
                return ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.restaurant, color: Colors.green),
                        title: Text(
                          recipe['Recipe Title'] ?? 'Untitled Recipe',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          recipe['Recipe Category'] ?? 'Uncategorized',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to recipe detail screen
                          _showRecipeDetails(context, recipe);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add voice command button
          _showVoiceCommandDialog(context);
        },
        child: const Icon(Icons.mic),
      ),
    );
  }

  void _showRecipeDetails(BuildContext context, Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recipe['Recipe Title'] ?? 'Recipe Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe['Description'] != null) ...[
                Text(
                  recipe['Description'],
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
              ],
              if (recipe['Recipe Ingredients Quantities'] != null) ...[
                const Text(
                  "Ingredients:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(recipe['Recipe Ingredients Quantities']),
                const SizedBox(height: 16),
              ],
              if (recipe['Recipe Instructions'] != null) ...[
                const Text(
                  "Instructions:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(recipe['Recipe Instructions']),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showVoiceCommandDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Voice Commands"),
        content: const Text("Voice feature coming soon!\n\nYou'll be able to:\n• Ask for recipes\n• Set timers\n• Convert measurements"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}