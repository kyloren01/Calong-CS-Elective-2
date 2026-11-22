import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
import '../../providers/navigation_providers.dart';
import '../../utils/price_format.dart';
import '../../widgets/order_card.dart';

/// Shown right after checkout, with what the database saved.
class OrderConfirmationPage extends ConsumerWidget {
  const OrderConfirmationPage({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    void leaveTo(CustomerTab tab) {
      ref.read(customerTabProvider.notifier).show(tab);
      Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order confirmed')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 44,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thank you for your order!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your order number is ${order.number}.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Total: ${formatPrice(order.total)}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                OrderCard(order: order),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => leaveTo(CustomerTab.orders),
                  child: const Text('View my orders'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => leaveTo(CustomerTab.shop),
                  child: const Text('Keep shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
