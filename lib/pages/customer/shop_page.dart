import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/brand.dart';
import '../../widgets/catalog_view.dart';
import '../../widgets/message_view.dart';
import '../../widgets/product_card.dart';
import 'product_details_page.dart';

/// The customer's product list, with an Add to cart button on each product.
class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => refreshCatalog(ref.invalidate),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CatalogView(
        emptyMessage: 'The shop has nothing for sale right now.',
        cardBuilder: (context, product) => _CustomerProductCard(product),
      ),
    );
  }
}

class _CustomerProductCard extends ConsumerWidget {
  const _CustomerProductCard(this.product);

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = ref.watch(
      cartProvider.select((cart) => cart.quantityOf(product.id)),
    );
    return ProductCard(
      product: product,
      badge: inCart == 0 ? null : '$inCart in cart',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProductDetailsPage(product: product),
        ),
      ),
      footer: AddToCartButton(product: product),
    );
  }
}

/// Adds one to the cart. It is off when the product is out of stock, or when
/// the cart already holds everything that is left.
class AddToCartButton extends ConsumerWidget {
  const AddToCartButton({super.key, required this.product, this.quantity = 1});

  final Product product;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inCart = ref.watch(
      cartProvider.select((cart) => cart.quantityOf(product.id)),
    );
    final full = inCart + quantity > product.stock;
    final label = product.isOutOfStock
        ? 'Out of stock'
        : full && inCart > 0
        ? 'No more left'
        : 'Add to cart';

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: product.isOutOfStock || full
            ? null
            : () {
                final problem = ref
                    .read(cartProvider.notifier)
                    .add(product, quantity: quantity);
                showMessage(
                  context,
                  problem ??
                      (quantity == 1
                          ? '${product.name} added to your cart.'
                          : '$quantity × ${product.name} added to your cart.'),
                );
              },
        icon: Icon(
          product.isOutOfStock
              ? Icons.remove_shopping_cart_outlined
              : Icons.add_shopping_cart_rounded,
          size: 18,
        ),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
