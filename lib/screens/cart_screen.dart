import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../routing/app_router.dart';
import '../state/shop_store.dart';
import '../theme/app_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ShopStore>();
    final lines = store.cartLines;
    final total = store.cartTotal;
    final quantity = store.cartQuantity;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart ($quantity)'),
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
      ),
      body: lines.isEmpty
          ? _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: line.product.primaryColor,
                            child: Icon(line.product.icon, color: Colors.white),
                          ),
                          title: Text(
                            line.product.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '\$${line.unitPrice.toStringAsFixed(2)} each\n'
                            'Line total: \$${line.total.toStringAsFixed(2)}',
                          ),
                          trailing: _QuantityControls(line: line),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$quantity products',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: AppColors.orange,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              final receipt = context
                                  .read<ShopStore>()
                                  .checkout();
                              if (receipt != null && context.mounted) {
                                context.go(AppRoutes.checkout);
                              }
                            },
                            icon: const Icon(Icons.payment_rounded),
                            label: const Text('Checkout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.orange,
          ),
          const SizedBox(height: 16),
          const Text('Your cart is empty'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go(AppRoutes.home),
            icon: const Icon(Icons.storefront_rounded),
            label: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  const _QuantityControls({required this.line});

  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ShopStore>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease quantity',
          onPressed: () => store.decrement(line.product),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '${line.quantity}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        IconButton(
          tooltip: 'Increase quantity',
          onPressed: () => store.add(line.product),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}
