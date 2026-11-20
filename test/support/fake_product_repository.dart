import 'dart:math' as math;

import 'package:my_first_flutter_ui/data/product_repository.dart';
import 'package:my_first_flutter_ui/models/product.dart';

/// The 24 sample rows from supabase/schema.sql, with the same ids.
const seedProducts = [
  Product(id: 1, name: 'Aurora Headphones', description: 'Wireless audio with soft cushions.', category: 'Audio', price: 129),
  Product(id: 2, name: 'Echo Mini Speaker', description: 'Pocket-size speaker with punchy bass.', category: 'Audio', price: 59),
  Product(id: 3, name: 'Pulse Earbuds', description: 'True wireless buds with a charging case.', category: 'Audio', price: 89),
  Product(id: 4, name: 'Studio Mic', description: 'USB condenser mic for calls and streams.', category: 'Audio', price: 149),
  Product(id: 5, name: 'Urban Backpack', description: 'Compact carry with padded storage.', category: 'Bags', price: 74),
  Product(id: 6, name: 'Transit Sling', description: 'Slim crossbody bag for daily essentials.', category: 'Bags', price: 39),
  Product(id: 7, name: 'Weekender Duffel', description: 'Roomy duffel for short trips.', category: 'Bags', price: 119),
  Product(id: 8, name: 'Laptop Sleeve', description: 'Padded sleeve for 13 to 15 inch laptops.', category: 'Bags', price: 29),
  Product(id: 9, name: 'Pulse Watch', description: 'Fitness tracking in a clean shell.', category: 'Wearables', price: 199),
  Product(id: 10, name: 'Fit Band', description: 'Slim tracker for steps and sleep.', category: 'Wearables', price: 49),
  Product(id: 11, name: 'Trail Watch', description: 'Rugged GPS watch for outdoor runs.', category: 'Wearables', price: 249),
  Product(id: 12, name: 'Glow Desk Lamp', description: 'Warm light with touch controls.', category: 'Home', price: 48),
  Product(id: 13, name: 'Aroma Diffuser', description: 'Quiet mist diffuser with a soft glow.', category: 'Home', price: 42),
  Product(id: 14, name: 'Cloud Pillow', description: 'Memory foam pillow for deep sleep.', category: 'Home', price: 35),
  Product(id: 15, name: 'Sprint Sneakers', description: 'Breathable everyday runners.', category: 'Footwear', price: 96),
  Product(id: 16, name: 'Trail Runners', description: 'Grippy shoes for rough paths.', category: 'Footwear', price: 135),
  Product(id: 17, name: 'Slide Sandals', description: 'Cushioned slides for quick errands.', category: 'Footwear', price: 25),
  Product(id: 18, name: 'Brew Kit', description: 'Portable pour-over coffee tools.', category: 'Kitchen', price: 58),
  Product(id: 19, name: 'Steel Tumbler', description: 'Keeps drinks cold for 24 hours.', category: 'Kitchen', price: 22),
  Product(id: 20, name: 'Chef Knife', description: 'Sharp stainless blade for daily prep.', category: 'Kitchen', price: 64),
  Product(id: 21, name: 'Bento Box', description: 'Leak-proof lunch box with dividers.', category: 'Kitchen', price: 18),
  Product(id: 22, name: 'Power Bank', description: '10,000 mAh charger with USB-C.', category: 'Tech', price: 45),
  Product(id: 23, name: 'Wireless Charger', description: 'Fast charging pad for phones and buds.', category: 'Tech', price: 32),
  Product(id: 24, name: 'Mechanical Keyboard', description: 'Tactile keys with a warm backlight.', category: 'Tech', price: 110),
];

typedef PageRequest = ({int page, PriceRange? price, String? category});

/// An in-memory products table that filters, sorts, and pages like the
/// Supabase query in SupabaseProductRepository.
class FakeProductRepository implements ProductRepository {
  FakeProductRepository({List<Product> products = seedProducts})
    : products = [...products];

  final List<Product> products;

  /// Every fetchProducts call, in order.
  final List<PageRequest> pageRequests = [];

  /// When set, every call fails with this error.
  Object? error;

  /// When set, fetchProducts waits for it before answering.
  Future<void> Function(int page)? beforePage;

  int _nextId = 1000;

  Product byName(String name) => products.firstWhere((p) => p.name == name);

  Future<void> _answer() async {
    await Future<void>.delayed(Duration.zero);
    final failure = error;
    if (failure != null) throw failure;
  }

  @override
  Future<PriceRange?> fetchPriceBounds() async {
    await _answer();
    if (products.isEmpty) return null;
    final prices = products.map((p) => p.price);
    return PriceRange(prices.reduce(math.min), prices.reduce(math.max));
  }

  @override
  Future<List<String>> fetchCategories() async {
    await _answer();
    return products.map((p) => p.category).toSet().toList()..sort();
  }

  @override
  Future<ProductPage> fetchProducts({
    required int page,
    required int pageSize,
    PriceRange? price,
    String? category,
  }) async {
    pageRequests.add((page: page, price: price, category: category));
    await beforePage?.call(page);
    await _answer();
    final matches =
        products
            .where(
              (p) =>
                  (price == null || price.contains(p.price)) &&
                  (category == null || p.category == category),
            )
            .toList()
          ..sort(
            (a, b) => a.price != b.price
                ? a.price.compareTo(b.price)
                : a.id.compareTo(b.id),
          );
    return ProductPage(
      products: matches.skip((page - 1) * pageSize).take(pageSize).toList(),
      totalCount: matches.length,
    );
  }

  @override
  Future<void> createProduct(ProductDraft draft) async {
    await _answer();
    products.add(_fromDraft(_nextId++, draft));
  }

  @override
  Future<void> updateProduct(int id, ProductDraft draft) async {
    await _answer();
    final index = products.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw const ProductRepositoryException('Nothing was updated.');
    }
    products[index] = _fromDraft(id, draft);
  }

  @override
  Future<void> deleteProduct(int id) async {
    await _answer();
    final before = products.length;
    products.removeWhere((p) => p.id == id);
    if (products.length == before) {
      throw const ProductRepositoryException('Nothing was deleted.');
    }
  }

  static Product _fromDraft(int id, ProductDraft draft) => Product(
    id: id,
    name: draft.name,
    description: draft.description,
    category: draft.category,
    price: draft.price,
  );
}
