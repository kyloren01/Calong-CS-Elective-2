import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import 'product_repository.dart';

/// Reads and writes the `products` table with Supabase queries.
class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'products';
  static const _timeout = Duration(seconds: 20);

  @override
  Future<PriceRange?> fetchPriceBounds() => _guard(() async {
    // Two one-row queries: the cheapest product and the priciest product.
    final [cheapest, priciest] = await Future.wait([
      _client
          .from(_table)
          .select('price')
          .order('price', ascending: true)
          .limit(1),
      _client
          .from(_table)
          .select('price')
          .order('price', ascending: false)
          .limit(1),
    ]);
    if (cheapest.isEmpty || priciest.isEmpty) return null;
    return PriceRange(_price(cheapest.first), _price(priciest.first));
  });

  @override
  Future<List<String>> fetchCategories() => _guard(() async {
    final rows = await _client
        .from(_table)
        .select('category')
        .order('category', ascending: true);
    return {for (final row in rows) row['category'] as String}.toList();
  });

  @override
  Future<ProductPage> fetchProducts({
    required int page,
    required int pageSize,
    PriceRange? price,
    String? category,
  }) => _guard(() async {
    // range() is inclusive, so page 2 at 6 per page asks for rows 6 to 11.
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    try {
      final response =
          await _filter(_client.from(_table).select(), price, category)
              .order('price', ascending: true)
              // Equal prices are ordered by id, so no product shows up on two
              // pages.
              .order('id', ascending: true)
              .range(from, to)
              .count(CountOption.exact);
      return ProductPage(
        products: response.data.map(Product.fromJson).toList(),
        totalCount: response.count,
      );
    } on PostgrestException catch (error) {
      // PGRST103 means the page starts after the last match, for example
      // after deleting the only product on the last page. Count the matches
      // so the shop can move to the new last page.
      if (error.code != 'PGRST103') rethrow;
      final total = await _filter(
        _client.from(_table).count(CountOption.exact),
        price,
        category,
      );
      return ProductPage(products: const [], totalCount: total);
    }
  });

  @override
  Future<void> createProduct(ProductDraft draft) => _guard(() async {
    await _client.from(_table).insert(draft.toJson());
  });

  @override
  Future<void> updateProduct(int id, ProductDraft draft) => _guard(() async {
    final rows = await _client
        .from(_table)
        .update(draft.toJson())
        .eq('id', id)
        .select('id');
    // A missing row or a blocking RLS policy is not an error here. Supabase
    // just changes 0 rows, so check what came back.
    if (rows.isEmpty) {
      throw const ProductRepositoryException(
        'Nothing was updated. The product may have been deleted, or an RLS '
        'policy blocked the change.',
      );
    }
  });

  @override
  Future<void> deleteProduct(int id) => _guard(() async {
    final rows = await _client
        .from(_table)
        .delete()
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) {
      throw const ProductRepositoryException(
        'Nothing was deleted. The product may already be gone, or an RLS '
        'policy blocked the change.',
      );
    }
  });

  /// The price slider and category chips, as Supabase filters.
  PostgrestFilterBuilder<T> _filter<T>(
    PostgrestFilterBuilder<T> query,
    PriceRange? price,
    String? category,
  ) {
    var filtered = query;
    if (price != null) {
      filtered = filtered.gte('price', price.min).lte('price', price.max);
    }
    if (category != null) filtered = filtered.eq('category', category);
    return filtered;
  }

  static double _price(Map<String, dynamic> row) =>
      (row['price'] as num).toDouble();

  /// Adds a time limit and turns Supabase and network errors into messages
  /// a person can act on.
  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on ProductRepositoryException {
      rethrow;
    } on PostgrestException catch (error) {
      throw ProductRepositoryException(_describe(error));
    } on TimeoutException {
      throw const ProductRepositoryException(
        'Supabase took too long to answer. Check your connection and try again.',
      );
    } on ClientException {
      throw const ProductRepositoryException(
        'Could not reach Supabase. Check your internet connection and try again.',
      );
    }
  }

  static String _describe(PostgrestException error) => switch (error.code) {
    '42501' =>
      'Supabase blocked this request. Check the RLS policies on the products table.',
    '42P01' || 'PGRST205' =>
      'The products table was not found. Run supabase/schema.sql in the Supabase SQL Editor.',
    '23514' =>
      'Supabase rejected the product. Names cannot be blank and prices cannot be negative.',
    '401' =>
      'Supabase rejected the API key. Check SUPABASE_PUBLISHABLE_KEY in supabase.json.',
    _ => 'Supabase error: ${error.message}',
  };
}
