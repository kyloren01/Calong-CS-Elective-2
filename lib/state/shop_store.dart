import 'package:flutter/foundation.dart';

import '../data/product_data.dart';

class CartLine {
  CartLine({required this.product, required this.quantity});
  final Product product;
  int quantity;
  double get unitPrice => double.parse(product.price.replaceAll('\$', ''));
  double get total => unitPrice * quantity;
}

class PurchaseRecord {
  PurchaseRecord({required this.lines, required this.total, required this.date});
  final List<CartLine> lines;
  final double total;
  final DateTime date;
  int get quantity => lines.fold(0, (sum, line) => sum + line.quantity);
}

class CheckoutReceipt {
  CheckoutReceipt({required this.lines, required this.total});
  final List<CartLine> lines;
  final double total;
  int get quantity => lines.fold(0, (sum, line) => sum + line.quantity);
}

class ShopStore extends ChangeNotifier {
  final Map<String, CartLine> _cart = {};
  final List<PurchaseRecord> _purchases = [];

  List<CartLine> get cartLines => List.unmodifiable(_cart.values);
  List<PurchaseRecord> get purchases => List.unmodifiable(_purchases.reversed);
  int get cartQuantity => _cart.values.fold(0, (sum, line) => sum + line.quantity);
  double get cartTotal => _cart.values.fold(0, (sum, line) => sum + line.total);

  void add(Product product) {
    final line = _cart[product.id];
    if (line == null) {
      _cart[product.id] = CartLine(product: product, quantity: 1);
    } else {
      line.quantity++;
    }
    notifyListeners();
  }

  void decrement(Product product) {
    final line = _cart[product.id];
    if (line == null) return;
    line.quantity == 1 ? _cart.remove(product.id) : line.quantity--;
    notifyListeners();
  }

  CheckoutReceipt? checkout() {
    if (_cart.isEmpty) return null;
    final lines = _cart.values.map((line) => CartLine(product: line.product, quantity: line.quantity)).toList();
    final receipt = CheckoutReceipt(lines: lines, total: cartTotal);
    _purchases.add(PurchaseRecord(lines: lines, total: receipt.total, date: DateTime.now()));
    _cart.clear();
    notifyListeners();
    return receipt;
  }
}
