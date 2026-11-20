/// A product price, such as $129.00.
String formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

/// A slider label in whole dollars, such as $129.
String formatWholePrice(double price) => '\$${price.round()}';
