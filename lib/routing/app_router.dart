import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../data/product_data.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_confirmation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/unknown_product_screen.dart';

abstract class AppRoutes {
  static const home = '/';
  static const productDetail = '/details/:productId';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const notifications = '/notifications';

  static String productDetailLocation(String productId) {
    return '/details/$productId';
  }
}

GoRouter createAppRouter({required VoidCallback onToggleTheme}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomeScreen(onToggleTheme: onToggleTheme),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          final product = productById(state.pathParameters['productId']);

          if (product == null) {
            return const UnknownProductScreen();
          }

          return ProductDetailScreen(product: product);
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutConfirmationScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
