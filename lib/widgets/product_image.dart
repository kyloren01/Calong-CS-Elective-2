import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The icon and colors used for each category, so products need no image
/// column.
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

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.category, required this.height});

  final String category;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = CategoryStyle.of(category);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [style.start, style.end],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 14,
            child: Container(
              width: height * 0.16,
              height: height * 0.16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.38),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Icon(style.icon, size: height * 0.46, color: Colors.white),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.charcoal,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
