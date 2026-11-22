import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_exception.dart';
import '../../models/order.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/async_view.dart';
import '../../widgets/auth_form.dart' show ButtonSpinner;
import '../../widgets/message_view.dart';
import '../../widgets/order_card.dart';

/// Every customer's orders, newest first, with a status the admin can change.
class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  /// Null shows every status.
  OrderStatus? _filter;

  Future<void> _changeStatus(Order order, OrderStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref
        .read(orderStatusProvider.notifier)
        .update(order, status);
    showMessageOn(
      messenger,
      error == null
          ? 'Order ${order.number} is now ${status.label.toLowerCase()}.'
          : messageFor(error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(allOrdersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: orders.isLoading
                ? null
                : () => ref.invalidate(allOrdersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncView(
        value: orders,
        onRetry: () => ref.invalidate(allOrdersProvider),
        data: (orders) => orders.isEmpty
            ? const MessageView(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Orders appear here as soon as customers check out.',
              )
            : _buildList(orders),
      ),
    );
  }

  Widget _buildList(List<Order> orders) {
    final shown = [
      for (final order in orders)
        if (_filter == null || order.status == _filter) order,
    ];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              _filterChip('All', null, orders.length),
              for (final status in OrderStatus.values)
                _filterChip(
                  status.label,
                  status,
                  orders.where((order) => order.status == status).length,
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? MessageView(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'No ${_filter!.label.toLowerCase()} orders',
                  message: 'Choose another status to see more.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: OrderCard(
                        order: shown[index],
                        action: _StatusMenu(
                          order: shown[index],
                          onChanged: (status) =>
                              _changeStatus(shown[index], status),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, OrderStatus? status, int count) {
    final selected = _filter == status;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: selected ? theme.colorScheme.onPrimary : null,
        ),
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }
}

class _StatusMenu extends ConsumerWidget {
  const _StatusMenu({required this.order, required this.onChanged});

  final Order order;
  final ValueChanged<OrderStatus> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saving = ref.watch(orderStatusProvider);
    return PopupMenuButton<OrderStatus>(
      tooltip: 'Change the status of order ${order.number}',
      enabled: saving == null,
      initialValue: order.status,
      onSelected: (status) {
        if (status != order.status) onChanged(status);
      },
      itemBuilder: (_) => [
        for (final status in OrderStatus.values)
          PopupMenuItem(value: status, child: Text(status.label)),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OrderStatusChip(order.status),
          const SizedBox(width: 4),
          if (saving == order.id)
            const Padding(padding: EdgeInsets.all(3), child: ButtonSpinner())
          else
            const Icon(Icons.arrow_drop_down_rounded),
        ],
      ),
    );
  }
}
