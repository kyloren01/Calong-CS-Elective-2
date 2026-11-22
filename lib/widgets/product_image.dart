import 'package:flutter/material.dart';

import '../models/product.dart';

/// The icon and colors used while a product has no picture.
class CategoryStyle {
  const CategoryStyle(this.icon, this.start, this.end);

  final IconData icon;
  final Color start;
  final Color end;

  static CategoryStyle of(String category) => switch (category.toLowerCase()) {
    'audio' => const CategoryStyle(
      Icons.headphones_rounded,
      Color(0xFFFFB13B),
      Color(0xFFFF6B35),
    ),
    'bags' => const CategoryStyle(
      Icons.backpack_rounded,
      Color(0xFFFFC65A),
      Color(0xFFFF8A1D),
    ),
    'wearables' => const CategoryStyle(
      Icons.watch_rounded,
      Color(0xFFFF7A45),
      Color(0xFFFFA21A),
    ),
    'home' => const CategoryStyle(
      Icons.light_rounded,
      Color(0xFFFFA21A),
      Color(0xFFFFD166),
    ),
    'footwear' => const CategoryStyle(
      Icons.directions_run_rounded,
      Color(0xFFFF8A1D),
      Color(0xFFFF5630),
    ),
    'kitchen' => const CategoryStyle(
      Icons.coffee_rounded,
      Color(0xFFFFB545),
      Color(0xFFFF7A00),
    ),
    'tech' => const CategoryStyle(
      Icons.devices_other_rounded,
      Color(0xFFFF9F43),
      Color(0xFFFF6B35),
    ),
    _ => const CategoryStyle(
      Icons.shopping_bag_rounded,
      Color(0xFFFFB13B),
      Color(0xFFFF8A1D),
    ),
  };
}

/// The product's picture, or artwork for its category when there is none
/// (or it can't be loaded).
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.product, this.radius = 12});

  final Product product;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final artwork = CategoryArtwork(category: product.categoryName);
    final url = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? artwork
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              semanticLabel: product.name,
              errorBuilder: (_, _, _) => artwork,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
            ),
    );
  }
}

class CategoryArtwork extends StatelessWidget {
  const CategoryArtwork({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.start, style.end],
        ),
      ),
      child: SizedBox.expand(
        child: FractionallySizedBox(
          heightFactor: 0.46,
          child: FittedBox(child: Icon(style.icon, color: Colors.white)),
        ),
      ),
    );
  }
}
