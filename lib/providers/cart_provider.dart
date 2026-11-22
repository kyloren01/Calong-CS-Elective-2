import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../utils/price_format.dart';
import 'service_providers.dart';
import 'session_providers.dart';

/// The customer's cart. It lives here instead of on a page, so it survives
/// moving between screens.
final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() {
    // Signing out (or in as someone else) starts an empty cart.
    ref.watch(userIdProvider);
    return const Cart();
  }

  /// Returns null when it worked, or a message saying why not.
  String? add(Product product, {int quantity = 1}) {
    if (product.isOutOfStock) return '${product.name} is out of stock.';
    final inCart = state.quantityOf(product.id);
    if (inCart + quantity > product.stock) {
      return inCart == 0
          ? 'Only ${product.stock} of ${product.name} left.'
          : 'Only ${product.stock} of ${product.name} left, and $inCart '
                '${inCart == 1 ? 'is' : 'are'} already in your cart.';
    }
    _put(CartLine(product: product, quantity: inCart + quantity));
    return null;
  }

  /// Returns null when it worked, or a message saying why not.
  String? setQuantity(Product product, int quantity) {
    if (quantity < 1) {
      remove(product);
      return null;
    }
    if (quantity > product.stock) {
      return 'Only ${product.stock} of ${product.name} left.';
    }
    _put(CartLine(product: product, quantity: quantity));
    return null;
  }

  void remove(Product product) => state = Cart([
    for (final line in state.lines)
      if (line.product.id != product.id) line,
  ]);

  void clear() => state = const Cart();

  /// Loads the current price and stock of everything in the cart, since
  /// other customers and admins may have changed them. Returns what changed,
  /// in words for the customer.
  Future<List<String>> refresh() async {
    final ids = [for (final line in state.lines) line.product.id];
    if (ids.isEmpty) return const [];
    final customerId = ref.read(userIdProvider);
    final current = {
      for (final product
          in await ref.read(productServiceProvider).fetchByIds(ids))
        product.id: product,
    };
    // Signed out meanwhile: this is no longer the same person's cart.
    if (!ref.mounted || ref.read(userIdProvider) != customerId) return const [];

    final changes = <String>[];
    final lines = <CartLine>[];
    for (final line in state.lines) {
      final product = current[line.product.id];
      final name = line.product.name;
      if (!ids.contains(line.product.id)) {
        // Added while the prices were loading, so it is already current.
        lines.add(line);
      } else if (product == null) {
        changes.add('$name is no longer sold and was removed.');
      } else if (product.isOutOfStock) {
        changes.add('$name is out of stock and was removed.');
      } else {
        var quantity = line.quantity;
        if (quantity > product.stock) {
          quantity = product.stock;
          changes.add(
            'Only $quantity of $name left, so your cart now has '
            '$quantity.',
          );
        }
        if (product.price != line.product.price) {
          changes.add('$name now costs ${formatPrice(product.price)}.');
        }
        lines.add(CartLine(product: product, quantity: quantity));
      }
    }
    state = Cart(lines);
    return changes;
  }

  void _put(CartLine changed) {
    final exists = state.quantityOf(changed.product.id) > 0;
    state = Cart([
      for (final line in state.lines)
        line.product.id == changed.product.id ? changed : line,
      if (!exists) changed,
    ]);
  }
}
