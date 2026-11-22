import 'product.dart';

class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get _totalCents => (product.price * 100).round() * quantity;

  double get total => _totalCents / 100;
}

/// What the customer is about to buy. Prices here are only for showing a
/// running total: the database uses its own prices at checkout.
class Cart {
  const Cart([this.lines = const []]);

  final List<CartLine> lines;

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  // Added up in cents, so the total never shows rounding errors.
  double get total =>
      lines.fold(0, (sum, line) => sum + line._totalCents) / 100;

  int quantityOf(int productId) {
    for (final line in lines) {
      if (line.product.id == productId) return line.quantity;
    }
    return 0;
  }
}
