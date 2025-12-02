import 'package:flutter/material.dart';
import 'package:tamubot/modules/recipes/recipes_page.dart';
import 'package:tamubot/modules/recipes/mealplan_page.dart';

class RecipesDividerPage extends StatelessWidget {
  const RecipesDividerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Kitchen'),
        backgroundColor: const Color.fromARGB(168, 6, 172, 80),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bookmarked Recipes Card
            _CategoryCard(
              title: 'Bookmarked Recipes',
              subtitle: 'Your saved recipes collection',
              image: 'assets/food.png', 
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecipesPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            
            // My Meal Plans Card
            _CategoryCard(
              title: 'My Meal Plans',
              subtitle: 'Plan your weekly meals',
              image: 'assets/mealplan.png',
              onTap: () {
                // Navigate to meal plans page (to be implemented)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealPlansPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 200, // Increased height for larger cards
          child: Stack(
            children: [
              // Full card background image
              Positioned.fill(
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                ),
              ),
              
              // Side fade overlay (left side for text readability)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.6), // Dark on left where text is
                        Colors.black.withOpacity(0.3), // Medium in middle
                        Colors.transparent, // Transparent on right side
                      ],
                      stops: [0.0, 0.4, 0.8],
                    ),
                  ),
                ),
              ),
              
              // Additional bottom fade for the "Explore" text
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(28.0), // Increased padding for larger card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and subtitle at top
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26, // Slightly larger text
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text for contrast against dark fade
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black87,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white, // White text
                            shadows: [
                              Shadow(
                                blurRadius: 3,
                                color: Colors.black87,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Arrow indicator at bottom
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Explore',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

