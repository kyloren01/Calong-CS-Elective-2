import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/price_format.dart';
import 'product_image.dart';

/// One product in the grid. The [footer] holds the role's buttons: add to
/// cart for customers, edit and delete for admins.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.footer,
    this.onTap,
    this.showExactStock = false,
    this.badge,
  });

  final Product product;
  final Widget footer;
  final VoidCallback? onTap;

  /// Admins see every stock number. Customers only hear when it runs low.
  final bool showExactStock;

  /// Shown over the picture, such as "2 in cart".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 112,
                child: Stack(
                  children: [
                    Positioned.fill(child: ProductImage(product: product)),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Pill(product.categoryName),
                      ),
                    ),
                    if (badge case final badge?)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Pill(
                          badge,
                          background: scheme.primary,
                          foreground: scheme.onPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatPrice(product.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              StockLabel(product.stock, exact: showExactStock),
              const SizedBox(height: 8),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

/// "In stock", "Only 3 left", or "Out of stock".
class StockLabel extends StatelessWidget {
  const StockLabel(this.stock, {super.key, this.exact = false});

  final int stock;
  final bool exact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (text, color) = switch (stock) {
      <= 0 => ('Out of stock', scheme.error),
      <= 5 => ('Only $stock left', scheme.primary),
      _ when exact => ('$stock in stock', scheme.tertiary),
      _ => ('In stock', scheme.tertiary),
    };
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
    );
  }
}

/// A small rounded label.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.background, this.foreground});

  final String text;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: background ?? Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: foreground ?? const Color(0xFF222831),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
