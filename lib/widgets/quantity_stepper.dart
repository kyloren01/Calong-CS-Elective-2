import 'package:flutter/material.dart';

/// Minus, a number, and plus. Plus stops at [max].
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.max,
    required this.onChanged,
    this.min = 1,
    this.label = 'quantity',
  });

  final int quantity;
  final int min;
  final int max;

  /// Null turns the buttons off, for example while ordering.
  final ValueChanged<int>? onChanged;

  /// What is being counted, for tooltips and screen readers.
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = onChanged;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease $label',
            visualDensity: VisualDensity.compact,
            onPressed: change == null || quantity <= min
                ? null
                : () => change(quantity - 1),
            icon: const Icon(Icons.remove_rounded, size: 20),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 24),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall,
            ),
          ),
          IconButton(
            tooltip: quantity >= max ? 'No more in stock' : 'Increase $label',
            visualDensity: VisualDensity.compact,
            onPressed: change == null || quantity >= max
                ? null
                : () => change(quantity + 1),
            icon: const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
