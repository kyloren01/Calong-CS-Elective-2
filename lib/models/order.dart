/// The order statuses the database accepts. The names match its values.
enum OrderStatus {
  pending('Pending'),
  processing('Processing'),
  done('Done'),
  cancelled('Cancelled');

  const OrderStatus(this.label);

  final String label;

  static OrderStatus parse(String value) =>
      values.asNameMap()[value] ?? pending;
}

/// One line of an order. The name and price are copies made at checkout, so
/// they never change afterwards.
class OrderItem {
  const OrderItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productName: json['product_name'] as String,
    unitPrice: (json['unit_price'] as num).toDouble(),
    quantity: (json['quantity'] as num).toInt(),
  );

  final String productName;
  final double unitPrice;
  final int quantity;

  double get total => (unitPrice * 100).round() * quantity / 100;
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.items,
    this.customerName,
    this.customerEmail,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Only the admin's list asks for the customer.
    final customer = json['profiles'] as Map<String, dynamic>?;
    final name =
        '${customer?['firstname'] ?? ''} ${customer?['lastname'] ?? ''}'.trim();
    return Order(
      id: (json['id'] as num).toInt(),
      status: OrderStatus.parse(json['status'] as String),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      items: [
        for (final item in json['order_items'] as List? ?? const [])
          OrderItem.fromJson(item as Map<String, dynamic>),
      ],
      customerName: name.isEmpty ? null : name,
      customerEmail: customer?['email'] as String?,
    );
  }

  final int id;
  final OrderStatus status;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String? customerName;
  final String? customerEmail;

  /// The order number people see, such as #00042.
  String get number => '#${id.toString().padLeft(5, '0')}';

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}
