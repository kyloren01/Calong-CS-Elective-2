import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../utils/price_format.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';
import 'shop_page.dart';

/// One product in full, with a choice of how many to add.
class ProductDetailsPage extends ConsumerStatefulWidget {
  const ProductDetailsPage({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends ConsumerState<ProductDetailsPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = widget.product;
    final inCart = ref.watch(
      cartProvider.select((cart) => cart.quantityOf(product.id)),
    );
    final canAdd = product.stock - inCart;
    final quantity = canAdd < 1 ? 1 : _quantity.clamp(1, canAdd);

    final picture = AspectRatio(
      aspectRatio: 4 / 3,
      child: ProductImage(product: product, radius: 20),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pill(
          product.categoryName,
          background: theme.colorScheme.secondaryContainer,
          foreground: theme.colorScheme.onSecondaryContainer,
        ),
        const SizedBox(height: 12),
        Text(product.name, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          formatPrice(product.price),
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        StockLabel(product.stock),
        const SizedBox(height: 16),
        Text(
          product.description.isEmpty
              ? 'No description yet.'
              : product.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (!product.isOutOfStock) ...[
          Row(
            children: [
              Text('Quantity', style: theme.textTheme.titleSmall),
              const Spacer(),
              QuantityStepper(
                quantity: quantity,
                max: canAdd,
                onChanged: canAdd < 1
                    ? null
                    : (value) => setState(() => _quantity = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        AddToCartButton(product: product, quantity: quantity),
        if (inCart > 0) ...[
          const SizedBox(height: 10),
          Text(
            '$inCart in your cart',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: constraints.maxWidth >= 720
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: picture),
                        const SizedBox(width: 32),
                        Expanded(child: details),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [picture, const SizedBox(height: 20), details],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
