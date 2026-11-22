import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/navigation_providers.dart';
import '../../providers/order_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/message_view.dart';
import '../../widgets/order_card.dart';

/// The customer's own orders, newest first.
class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: orders.isLoading
                ? null
                : () => ref.invalidate(myOrdersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncView(
        value: orders,
        onRetry: () => ref.invalidate(myOrdersProvider),
        data: (orders) => orders.isEmpty
            ? MessageView(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Orders you place will be listed here.',
                action: FilledButton(
                  onPressed: () => ref
                      .read(customerTabProvider.notifier)
                      .show(CustomerTab.shop),
                  child: const Text('Start shopping'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: OrderCard(order: orders[index]),
                  ),
                ),
              ),
      ),
    );
  }
}
