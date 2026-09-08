import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/shop_store.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchases = context.watch<ShopStore>().purchases;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: purchases.isEmpty
          ? const Center(child: Text('No purchases yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: purchases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Purchase completed', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final line in purchase.lines) Text('${line.product.name} x${line.quantity}  -  \$${line.total.toStringAsFixed(2)}'),
                  const Divider(height: 20),
                  Text('${purchase.quantity} products  •  \$${purchase.total.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w800)),
                ])));
              },
            ),
    );
  }
}
