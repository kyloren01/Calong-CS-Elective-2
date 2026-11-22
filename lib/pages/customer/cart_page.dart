import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_exception.dart';
import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../providers/navigation_providers.dart';
import '../../providers/order_providers.dart';
import '../../utils/price_format.dart';
import '../../widgets/auth_form.dart' show ButtonSpinner;
import '../../widgets/message_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';
import 'order_confirmation_page.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  /// What changed in the shop since these products were added.
  List<String> _changes = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  /// Shows current prices and stock whenever the cart is opened.
  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _changes = const []);
    final List<String> changes;
    try {
      changes = await ref.read(cartProvider.notifier).refresh();
    } catch (_) {
      return; // Checkout checks everything again.
    }
    if (mounted) setState(() => _changes = changes);
  }

  Future<void> _checkout() async {
    final order = await ref.read(checkoutProvider.notifier).placeOrder();
    if (!mounted) return;
    if (order == null) {
      // The reason normally shows above the Checkout button. When everything
      // sold out, the cart is empty and that button is gone.
      final error = ref.read(checkoutProvider).error;
      if (error != null && ref.read(cartProvider).isEmpty) {
        setState(() => _changes = [messageFor(error)]);
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationPage(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(customerTabProvider, (_, tab) {
      if (tab == CustomerTab.cart) _refresh();
    });
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: Column(
        children: [
          if (_changes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Notice(
                _changes.join('\n'),
                isError: false,
                action: IconButton(
                  tooltip: 'Dismiss',
                  onPressed: () => setState(() => _changes = const []),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ),
            ),
          Expanded(
            child: cart.isEmpty
                ? MessageView(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Your cart is empty',
                    message:
                        'Add something you like, and it will wait for you '
                        'here.',
                    action: FilledButton(
                      onPressed: () => ref
                          .read(customerTabProvider.notifier)
                          .show(CustomerTab.shop),
                      child: const Text('Browse products'),
                    ),
                  )
                : _CartContent(cart: cart, onCheckout: _checkout),
          ),
        ],
      ),
    );
  }
}

/// The products and the total: side by side on wide screens.
class _CartContent extends ConsumerWidget {
  const _CartContent({required this.cart, required this.onCheckout});

  final Cart cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkout = ref.watch(checkoutProvider);
    final lines = ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cart.lines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _CartLineCard(
        key: ValueKey(cart.lines[index].product.id),
        line: cart.lines[index],
        enabled: !checkout.isLoading,
      ),
    );
    final summary = _Summary(
      cart: cart,
      busy: checkout.isLoading,
      error: checkout.error,
      onCheckout: onCheckout,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: lines),
                  SizedBox(
                    width: 340,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: summary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            Expanded(child: lines),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: summary,
            ),
          ],
        );
      },
    );
  }
}

class _CartLineCard extends ConsumerWidget {
  const _CartLineCard({super.key, required this.line, required this.enabled});

  final CartLine line;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final product = line.product;
    final cart = ref.read(cartProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(dimension: 76, child: ProductImage(product: product)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${formatPrice(product.price)} each',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          StockLabel(product.stock),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove ${product.name}',
                      visualDensity: VisualDensity.compact,
                      onPressed: enabled ? () => cart.remove(product) : null,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: enabled ? theme.colorScheme.error : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    QuantityStepper(
                      quantity: line.quantity,
                      max: product.stock,
                      label: product.name,
                      onChanged: enabled
                          ? (quantity) {
                              final problem = cart.setQuantity(
                                product,
                                quantity,
                              );
                              if (problem != null) {
                                showMessage(context, problem);
                              }
                            }
                          : null,
                    ),
                    Text(
                      formatPrice(line.total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.cart,
    required this.busy,
    required this.error,
    required this.onCheckout,
  });

  final Cart cart;
  final bool busy;
  final Object? error;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text('Total  ', style: theme.textTheme.titleSmall),
              Text(
                formatPrice(cart.total),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (error case final error?) ...[
            const SizedBox(height: 12),
            Notice(messageFor(error)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : onCheckout,
            icon: busy
                ? const ButtonSpinner()
                : const Icon(Icons.lock_outline_rounded, size: 18),
            label: Text(busy ? 'Placing your order…' : 'Checkout'),
          ),
          const SizedBox(height: 8),
          Text(
            'Prices and stock are checked again when you order.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
