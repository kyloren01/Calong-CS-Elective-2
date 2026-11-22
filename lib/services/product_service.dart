import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_exception.dart';
import '../models/catalog.dart';
import '../models/product.dart';
import 'image_service.dart';
import 'supabase_guard.dart';

/// Reads and edits the `products` table. RLS lets only admins edit it.
class ProductService {
  ProductService(this._client);

  final SupabaseClient _client;

  static const _table = 'products';
  static const _columns =
      'id, name, description, price, stock, category_id, image_path, '
      'categories(name)';

  /// The cheapest and priciest prices, or null when there are no products.
  Future<PriceRange?> fetchPriceBounds() => guard(() async {
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

  /// One page of products that match [filters], cheapest first. When the
  /// page no longer exists, this returns the last page instead.
  Future<ProductPage> fetchPage(CatalogFilters filters) => guard(() async {
    var page = await _fetchPage(filters, filters.page);
    final lastPage = ProductPage.pagesFor(page.totalCount);
    if (filters.page > lastPage) page = await _fetchPage(filters, lastPage);
    return page;
  });

  Future<ProductPage> _fetchPage(CatalogFilters filters, int page) async {
    // range() is inclusive, so page 2 at 6 per page asks for rows 6 to 11.
    final from = (page - 1) * ProductPage.size;
    final to = from + ProductPage.size - 1;
    try {
      final response =
          await _filter(_client.from(_table).select(_columns), filters)
              .order('price', ascending: true)
              // Equal prices are ordered by id, so no product is on two pages.
              .order('id', ascending: true)
              .range(from, to)
              .count(CountOption.exact);
      return ProductPage(
        products: response.data.map(_toProduct).toList(),
        totalCount: response.count,
        page: page,
      );
    } on PostgrestException catch (error) {
      // PGRST103: the page starts after the last match, such as after
      // deleting the only product on the last page. Just count the matches.
      if (error.code != 'PGRST103') rethrow;
      final total = await _filter(
        _client.from(_table).count(CountOption.exact),
        filters,
      );
      return ProductPage(products: const [], totalCount: total, page: page);
    }
  }

  /// The current name, price, and stock of these products. Deleted products
  /// are simply missing from the result.
  Future<List<Product>> fetchByIds(List<int> ids) => guard(() async {
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from(_table)
        .select(_columns)
        .inFilter('id', ids);
    return rows.map(_toProduct).toList();
  });

  Future<void> create(ProductDraft draft) =>
      guard(() => _client.from(_table).insert(draft.toJson()));

  Future<void> update(int id, ProductDraft draft) => guard(() async {
    final rows = await _client
        .from(_table)
        .update(draft.toJson())
        .eq('id', id)
        .select('id');
    _expectChange(rows);
  });

  Future<void> delete(int id) => guard(() async {
    final rows = await _client.from(_table).delete().eq('id', id).select('id');
    _expectChange(rows);
  });

  /// The search box, category chips, and price slider as Supabase filters.
  PostgrestFilterBuilder<T> _filter<T>(
    PostgrestFilterBuilder<T> query,
    CatalogFilters filters,
  ) {
    var filtered = query;
    if (filters.search.isNotEmpty) {
      // % and _ are wildcards in SQL, so search for them literally.
      final text = filters.search.replaceAllMapped(
        RegExp(r'[\\%_]'),
        (match) => '\\${match[0]}',
      );
      filtered = filtered.ilike('name', '%$text%');
    }
    if (filters.categoryId case final categoryId?) {
      filtered = filtered.eq('category_id', categoryId);
    }
    if (filters.price case final price?) {
      filtered = filtered.gte('price', price.min).lte('price', price.max);
    }
    return filtered;
  }

  Product _toProduct(Map<String, dynamic> row) => Product.fromJson(
    row,
    imageUrlFor: _client.storage.from(ImageService.bucket).getPublicUrl,
  );

  static double _price(Map<String, dynamic> row) =>
      (row['price'] as num).toDouble();

  // RLS doesn't raise an error when it blocks an edit: it changes 0 rows.
  static void _expectChange(List<Object?> rows) {
    if (rows.isNotEmpty) return;
    throw const AppException(
      'Nothing was changed. The product may be gone, or your account is not '
      'allowed to change it.',
      kind: AppErrorKind.permissionDenied,
    );
  }
}
