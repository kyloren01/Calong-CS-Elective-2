import 'package:flutter/material.dart';

import '../../widgets/adaptive_shell.dart';
import '../account_page.dart';
import 'admin_categories_page.dart';
import 'admin_orders_page.dart';
import 'admin_products_page.dart';

/// Everything an admin can open. Admins manage the shop and don't buy from
/// it, so there is no cart here.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => AdaptiveShell(
    index: _index,
    onSelected: (index) => setState(() => _index = index),
    tabs: const [
      ShellTab(
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2_rounded,
        page: AdminProductsPage(),
      ),
      ShellTab(
        label: 'Categories',
        icon: Icons.category_outlined,
        selectedIcon: Icons.category_rounded,
        page: AdminCategoriesPage(),
      ),
      ShellTab(
        label: 'Orders',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        page: AdminOrdersPage(),
      ),
      ShellTab(
        label: 'Account',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        page: AccountPage(),
      ),
    ],
  );
}
