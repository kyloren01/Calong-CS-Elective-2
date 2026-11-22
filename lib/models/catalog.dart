import 'product.dart';

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

/// What the person asked to see. Each change becomes one Supabase query.
class CatalogFilters {
  const CatalogFilters({
    this.search = '',
    this.categoryId,
    this.price,
    this.page = 1,
  });

  final String search;

  /// Null means every category.
  final int? categoryId;

  /// Null means every price.
  final PriceRange? price;

  /// Starts at 1.
  final int page;

  bool get isFiltering =>
      search.isNotEmpty || categoryId != null || price != null;

  @override
  bool operator ==(Object other) =>
      other is CatalogFilters &&
      other.search == search &&
      other.categoryId == categoryId &&
      other.price == price &&
      other.page == page;

  @override
  int get hashCode => Object.hash(search, categoryId, price, page);

  @override
  String toString() =>
      'CatalogFilters("$search", category $categoryId, $price, page $page)';
}

/// One page of products, plus how many match on all pages.
class ProductPage {
  const ProductPage({
    required this.products,
    required this.totalCount,
    required this.page,
  });

  /// Products per page, within the 6 to 8 of the pagination activity.
  static const size = 6;

  static int pagesFor(int count) => count == 0 ? 1 : (count / size).ceil();

  final List<Product> products;
  final int totalCount;

  /// The page actually shown. It can be lower than the page asked for, when
  /// the only product of the last page was deleted.
  final int page;

  int get totalPages => pagesFor(totalCount);

  /// Positions of the first and last product shown, such as 7 and 12.
  int get firstShown => products.isEmpty ? 0 : (page - 1) * size + 1;
  int get lastShown => products.isEmpty ? 0 : firstShown + products.length - 1;
}
