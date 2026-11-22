import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/date_format.dart';
import '../utils/price_format.dart';

/// One order with its items. Admins also see the customer, and [action] lets
/// them change the status.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.action});

  final Order order;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final customer = [?order.customerName, ?order.customerEmail].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
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
                      'Order ${order.number}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(formatDateTime(order.createdAt), style: muted),
                    if (customer.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(customer, style: muted),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              action ?? OrderStatusChip(order.status),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          OrderLines(order: order),
        ],
      ),
    );
  }
}

/// The items and total of an order, as they were at checkout.
class OrderLines extends StatelessWidget {
  const OrderLines({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity} × ${item.productName}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPrice(item.total),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (item.quantity > 1)
                      Text(
                        '${formatPrice(item.unitPrice)} each',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text('Total  ', style: theme.textTheme.titleSmall),
            Text(
              formatPrice(order.total),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      OrderStatus.pending => (scheme.surfaceContainerHighest, scheme.onSurface),
      OrderStatus.processing => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      OrderStatus.done => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      OrderStatus.cancelled => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}
