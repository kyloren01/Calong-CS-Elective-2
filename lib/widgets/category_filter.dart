import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "All" plus one chip per category. Picking a chip filters with
/// `.eq('category', ...)` in the Supabase query.
class CategoryFilter extends StatelessWidget {
  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in <String?>[null, ...categories])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category ?? 'All'),
                selected: selected == category,
                showCheckmark: false,
                selectedColor: AppColors.orange,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected == category ? Colors.white : null,
                ),
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}
