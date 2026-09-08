import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/product_data.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';
import '../widgets/product_image.dart';
import '../widgets/product_meta_pill.dart';
import '../state/shop_store.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(product.name),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 760
                ? 680.0
                : constraints.maxWidth;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: 'product-${product.id}',
                              child: ProductImage(
                                product: product,
                                height: 260,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  product.price,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color: AppColors.orange,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              product.longDescription,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final detail in product.meta)
                                  ProductMetaPill(label: detail),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                     onPressed: () {
                                       context.read<ShopStore>().add(product);
                                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added to cart.')));
                                     },
                                    icon: const Icon(
                                      Icons.shopping_bag_rounded,
                                    ),
                                    label: const Text('Add to cart'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton.filledTonal(
                                  tooltip: 'Share',
                                  onPressed: () {},
                                  icon: const Icon(Icons.ios_share_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
