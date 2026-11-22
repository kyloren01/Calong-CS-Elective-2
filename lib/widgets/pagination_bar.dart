import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Previous / page numbers / next. Each tap asks Supabase for that page.
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageSelected,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageSelected;

  /// Up to five page numbers, with the current page in the middle when
  /// possible.
  List<int> get visiblePages {
    final lastStart = math.max(1, totalPages - 4);
    final first = (page - 2).clamp(1, lastStart);
    final last = math.min(totalPages, first + 4);
    return [for (var number = first; number <= last; number++) number];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: page > 1 ? () => onPageSelected(page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        for (final number in visiblePages)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _PageNumber(
              number: number,
              selected: number == page,
              onPressed: () => onPageSelected(number),
            ),
          ),
        IconButton(
          tooltip: 'Next page',
          onPressed: page < totalPages ? () => onPageSelected(page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.number,
    required this.selected,
    required this.onPressed,
  });

  final int number;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.square(40)),
      fixedSize: const WidgetStatePropertyAll(Size.square(40)),
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    final label = Text('$number');
    return Semantics(
      label: 'Page $number',
      selected: selected,
      child: selected
          ? FilledButton(onPressed: onPressed, style: style, child: label)
          : TextButton(onPressed: onPressed, style: style, child: label),
    );
  }
}
