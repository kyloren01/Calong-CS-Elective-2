import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_router.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../state/shop_store.dart';

class ShopNavbar extends StatelessWidget implements PreferredSizeWidget {
  const ShopNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      toolbarHeight: 72,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Flutter Shopee',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Orange App',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Home'),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
               onPressed: () => context.push(AppRoutes.notifications),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.charcoal,
                  shape: BoxShape.circle,
                ),
                 child: Consumer<ShopStore>(
                   builder: (context, store, _) => Text(
                   '${store.purchases.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                 )),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
