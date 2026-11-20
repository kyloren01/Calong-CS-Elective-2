import '../models/product.dart';

/// What the shop needs from its database. The app uses
/// [SupabaseProductRepository]; the tests use an in-memory fake that behaves
/// the same way.
abstract class ProductRepository {
  /// The cheapest and priciest product prices, or null if there are none.
  Future<PriceRange?> fetchPriceBounds();

  /// Every category in use, A to Z, without duplicates.
  Future<List<String>> fetchCategories();

  /// One page of products sorted by price, and how many match on all pages.
  ///
  /// [page] starts at 1. A null [price] or [category] means "don't filter".
  Future<ProductPage> fetchProducts({
    required int page,
    required int pageSize,
    PriceRange? price,
    String? category,
  });

  Future<void> createProduct(ProductDraft draft);

  Future<void> updateProduct(int id, ProductDraft draft);

  Future<void> deleteProduct(int id);
}

/// A failure whose [message] can be shown to the person using the app.
class ProductRepositoryException implements Exception {
  const ProductRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
