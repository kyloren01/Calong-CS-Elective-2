import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_exception.dart';
import '../models/cart.dart';
import '../models/order.dart';
import 'supabase_guard.dart';

/// Places and reads orders.
class OrderService {
  OrderService(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, status, total, created_at, '
      'order_items(product_name, unit_price, quantity)';

  /// Checks out. Only product ids and quantities are sent: the place_order()
  /// database function looks up names, prices, and stock itself, and saves
  /// the order, its items, and the new stock together or not at all.
  Future<Order> placeOrder(List<CartLine> lines) async {
    try {
      return await guard(() async {
        final saved = await _client.rpc<Map<String, dynamic>>(
          'place_order',
          params: {
            'items': [
              for (final line in lines)
                {'product_id': line.product.id, 'quantity': line.quantity},
            ],
          },
        );
        return Order.fromJson(saved);
      });
    } on AppException catch (error) {
      if (error.kind != AppErrorKind.network) rethrow;
      // The answer got lost, so the order may or may not exist.
      throw AppException(
        '${error.message} Before ordering again, check Orders in case it '
        'already went through.',
        kind: error.kind,
      );
    }
  }

  /// The customer's own orders, newest first. RLS returns no one else's.
  Future<List<Order>> fetchMyOrders(String userId) => guard(() async {
    final rows = await _client
        .from('orders')
        .select(_columns)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .order('id', ascending: false);
    return rows.map(Order.fromJson).toList();
  });

  /// Every order with its customer, newest first. RLS lets only admins.
  Future<List<Order>> fetchAllOrders() => guard(() async {
    final rows = await _client
        .from('orders')
        .select('$_columns, profiles(email, firstname, lastname)')
        .order('created_at', ascending: false)
        .order('id', ascending: false);
    return rows.map(Order.fromJson).toList();
  });

  Future<void> updateStatus(int orderId, OrderStatus status) => guard(() async {
    final rows = await _client
        .from('orders')
        .update({'status': status.name})
        .eq('id', orderId)
        .select('id');
    // RLS doesn't raise an error when it blocks an edit: it changes 0 rows.
    if (rows.isEmpty) {
      throw const AppException(
        'Nothing was changed. Your account is not allowed to change orders.',
        kind: AppErrorKind.permissionDenied,
      );
    }
  });
}
