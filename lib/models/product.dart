/// One row of the Supabase `products` table (see supabase/schema.sql).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    // Supabase sends numeric columns as JSON numbers, such as 129 or 12.5.
    price: (json['price'] as num).toDouble(),
  );

  final int id;
  final String name;
  final String description;
  final String category;
  final double price;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.category == category &&
      other.price == price;

  @override
  int get hashCode => Object.hash(id, name, description, category, price);

  @override
  String toString() => 'Product($id, $name, $category, $price)';
}

/// The fields filled in on the add and edit forms.
class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.description,
    required this.category,
    required this.price,
  });

  final String name;
  final String description;
  final String category;
  final double price;

  /// The column values sent to Supabase. The database fills in `id` and
  /// `created_at` itself.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'price': price,
  };
}

/// An inclusive price range: the slider's limits, or the part of it a
/// customer selected.
class PriceRange {
  const PriceRange(this.min, this.max);

  /// Whole-dollar slider limits around the cheapest and priciest product.
  factory PriceRange.wholeDollars(PriceRange prices) {
    final min = prices.min.floorToDouble();
    final max = prices.max.ceilToDouble();
    // A slider needs some width, even when every product costs the same.
    return PriceRange(min, max > min ? max : min + 1);
  }

  final double min;
  final double max;

  bool contains(double price) => price >= min && price <= max;

  /// Whether this range includes every price in [other].
  bool covers(PriceRange other) => min <= other.min && max >= other.max;

  /// Moves both ends inside [bounds].
  PriceRange clampTo(PriceRange bounds) => PriceRange(
    min.clamp(bounds.min, bounds.max),
    max.clamp(bounds.min, bounds.max),
  );

  @override
  bool operator ==(Object other) =>
      other is PriceRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'PriceRange($min, $max)';
}

/// One page of query results, plus how many products match on all pages.
class ProductPage {
  const ProductPage({required this.products, required this.totalCount});

  final List<Product> products;
  final int totalCount;
}
