import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cart_provider.dart';
import '../../providers/navigation_providers.dart';
import '../../widgets/adaptive_shell.dart';
import '../account_page.dart';
import 'cart_page.dart';
import 'order_history_page.dart';
import 'shop_page.dart';

/// Everything a customer can open. There are no management pages here.
class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(customerTabProvider);
    final itemCount = ref.watch(cartProvider.select((cart) => cart.itemCount));
    return AdaptiveShell(
      index: tab.index,
      onSelected: (index) => ref
          .read(customerTabProvider.notifier)
          .show(CustomerTab.values[index]),
      // In the order of CustomerTab.
      tabs: [
        const ShellTab(
          label: 'Shop',
          icon: Icons.storefront_outlined,
          selectedIcon: Icons.storefront_rounded,
          page: ShopPage(),
        ),
        ShellTab(
          label: 'Cart',
          icon: Icons.shopping_cart_outlined,
          selectedIcon: Icons.shopping_cart_rounded,
          page: const CartPage(),
          badge: itemCount,
        ),
        const ShellTab(
          label: 'Orders',
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          page: OrderHistoryPage(),
        ),
        const ShellTab(
          label: 'Account',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          page: AccountPage(),
        ),
      ],
    );
  }
}
