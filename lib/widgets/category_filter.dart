import 'package:flutter/material.dart';

import '../models/category.dart';

/// "All" plus one chip per category. Picking a chip filters with
/// `.eq('category_id', ...)` in the Supabase query.
class CategoryFilter extends StatelessWidget {
  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;

  /// Null means "All".
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context, 'All', null),
          for (final category in categories)
            _chip(context, category.name, category.id),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String name, int? id) {
    final selected = selectedId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: selected,
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? Theme.of(context).colorScheme.onPrimary : null,
        ),
        onSelected: (_) => onSelected(id),
      ),
    );
  }
}
