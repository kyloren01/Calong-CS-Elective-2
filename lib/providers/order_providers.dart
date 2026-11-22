import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_exception.dart';
import '../models/order.dart';
import 'cart_provider.dart';
import 'catalog_providers.dart';
import 'service_providers.dart';
import 'session_providers.dart';

/// The customer's own orders, newest first.
final myOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return const [];
  return ref.watch(orderServiceProvider).fetchMyOrders(userId);
});

/// Places the order. The state holds the last order, or why it failed.
final checkoutProvider = NotifierProvider<CheckoutNotifier, AsyncValue<Order?>>(
  CheckoutNotifier.new,
);

class CheckoutNotifier extends Notifier<AsyncValue<Order?>> {
  bool _refreshingCart = false;

  @override
  AsyncValue<Order?> build() {
    ref.watch(userIdProvider);
    // "Only 2 left" is out of date once the customer changes the cart.
    ref.listen(cartProvider, (_, _) {
      if (state.hasError && !_refreshingCart) state = const AsyncData(null);
    });
    return const AsyncData(null);
  }

  /// Returns the saved order, or null when it failed. The cart is emptied
  /// only after the database confirmed the order.
  Future<Order?> placeOrder() async {
    final cart = ref.read(cartProvider);
    if (state.isLoading || cart.isEmpty) return null;
    final customerId = ref.read(userIdProvider);
    // If the customer signs out while the order is being placed, the cart
    // may already belong to someone else.
    bool sameCustomer() =>
        ref.mounted && ref.read(userIdProvider) == customerId;

    state = const AsyncLoading();
    try {
      final order = await ref.read(orderServiceProvider).placeOrder(cart.lines);
      if (!sameCustomer()) return null;
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      refreshCatalog(ref.invalidate); // The stock went down.
      state = AsyncData(order);
      return order;
    } catch (error, stackTrace) {
      if (!sameCustomer()) return null;
      state = AsyncError(error, stackTrace);
      if (errorKindOf(error) == AppErrorKind.rejected) {
        await _showCurrentStock();
      }
      return null;
    }
  }

  /// The database refused the order, usually because something sold out.
  /// Update the cart, so the customer sees what is left.
  Future<void> _showCurrentStock() async {
    _refreshingCart = true;
    try {
      refreshCatalog(ref.invalidate);
      await ref.read(cartProvider.notifier).refresh();
    } catch (_) {
      // The message about the refused order is already on screen.
    } finally {
      _refreshingCart = false;
    }
  }
}
