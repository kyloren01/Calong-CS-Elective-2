import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Data model for fruits
class FruitItem {
  final String name;
  final String emoji;
  final String description;
  final Color color;

  const FruitItem({
    required this.name,
    required this.emoji,
    required this.description,
    required this.color,
  });
}

const List<FruitItem> sampleFruits = [
  FruitItem(
    name: 'Apple',
    emoji: '🍎',
    description: 'Crisp, sweet red apple rich in fiber and vitamin C.',
    color: Color(0xFFFFEBEE),
  ),
  FruitItem(
    name: 'Banana',
    emoji: '🍌',
    description: 'Nutritious tropical fruit high in potassium.',
    color: Color(0xFFFFFDE7),
  ),
  FruitItem(
    name: 'Orange',
    emoji: '🍊',
    description: 'Juicy citrus fruit bursting with fresh vitamin C.',
    color: Color(0xFFFFF3E0),
  ),
  FruitItem(
    name: 'Grape',
    emoji: '🍇',
    description: 'Sweet and bite-sized grapes perfect for snacking.',
    color: Color(0xFFF3E5F5),
  ),
  FruitItem(
    name: 'Strawberry',
    emoji: '🍓',
    description: 'Deliciously sweet berry packed with antioxidants.',
    color: Color(0xFFFFEBEE),
  ),
  FruitItem(
    name: 'Watermelon',
    emoji: '🍉',
    description: 'Refreshing and hydrating summer fruit.',
    color: Color(0xFFE8F5E9),
  ),
];

// 1. Root Screen at "/"
class FruitListPage extends StatelessWidget {
  const FruitListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fruit Directory'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: sampleFruits.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final fruit = sampleFruits[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Text(
                fruit.emoji,
                style: const TextStyle(fontSize: 36),
              ),
              title: Text(
                fruit.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                fruit.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                // Navigate to nested sub-route /fruit/:name
                context.go('/fruit/${fruit.name.toLowerCase()}');
              },
            ),
          );
        },
      ),
    );
  }
}

// 2. Child / Nested Screen at "/fruit/:name"
class FruitDetailPage extends StatelessWidget {
  final String fruitName;

  const FruitDetailPage({super.key, required this.fruitName});

  @override
  Widget build(BuildContext context) {
    // Find matching fruit item or construct fallback
    final matchedFruit = sampleFruits.firstWhere(
      (f) => f.name.toLowerCase() == fruitName.toLowerCase(),
      orElse: () => FruitItem(
        name: fruitName,
        emoji: '🍇',
        description: 'A delicious fruit.',
        color: Colors.grey.shade100,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${matchedFruit.name} Details'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: matchedFruit.color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    matchedFruit.emoji,
                    style: const TextStyle(fontSize: 100),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                matchedFruit.name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'URL Path: /fruit/$fruitName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                matchedFruit.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/');
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Fruit List'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
