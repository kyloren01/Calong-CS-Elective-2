import 'package:flutter/material.dart';

import '../models/catalog.dart';
import '../utils/price_format.dart';

/// A two-thumb price slider. The labels follow the thumbs while dragging,
/// but the Supabase query only runs once the thumb is released.
class PriceFilter extends StatefulWidget {
  const PriceFilter({
    super.key,
    required this.bounds,
    required this.selected,
    required this.onChanged,
  });

  /// The cheapest and priciest product, in whole dollars.
  final PriceRange bounds;
  final PriceRange selected;
  final ValueChanged<PriceRange> onChanged;

  @override
  State<PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends State<PriceFilter> {
  // The thumbs' position while a drag is in progress.
  RangeValues? _dragging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bounds = widget.bounds;
    final selected = widget.selected.clampTo(bounds);
    final values = _dragging ?? RangeValues(selected.min, selected.max);
    final span = bounds.max - bounds.min;
    final hint = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Price', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              '${formatWholePrice(values.start)} – ${formatWholePrice(values.end)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        RangeSlider(
          min: bounds.min,
          max: bounds.max,
          // $1 steps. Very wide ranges slide smoothly and round on release.
          divisions: span <= 1000 ? span.round() : null,
          values: values,
          labels: RangeLabels(
            formatWholePrice(values.start),
            formatWholePrice(values.end),
          ),
          onChanged: (range) => setState(() => _dragging = range),
          onChangeEnd: (range) {
            setState(() => _dragging = null);
            widget.onChanged(
              PriceRange(
                range.start.roundToDouble(),
                range.end.roundToDouble(),
              ),
            );
          },
        ),
        Row(
          children: [
            Text(formatWholePrice(bounds.min), style: hint),
            const Spacer(),
            Text(formatWholePrice(bounds.max), style: hint),
          ],
        ),
      ],
    );
  }
}
