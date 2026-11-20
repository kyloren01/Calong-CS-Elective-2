import '../models/product.dart';

enum ShopStatus { initial, loading, success, failure }

/// Everything the shop screen shows. The Cubit replaces it with a new copy
/// on every change.
class ShopState {
  const ShopState({
    this.status = ShopStatus.initial,
    this.products = const [],
    this.page = 1,
    this.totalCount = 0,
    this.priceBounds,
    this.selectedPrice,
    this.categories = const [],
    this.selectedCategory,
    this.errorMessage,
  });

  /// Products per page. The activity allows 6 to 8.
  static const pageSize = 6;

  /// How many pages [count] products fill. An empty result is still 1 page.
  static int pagesFor(int count) => count == 0 ? 1 : (count / pageSize).ceil();

  final ShopStatus status;

  /// Only the current page of products, exactly as Supabase returned them.
  final List<Product> products;

  /// The current page, starting at 1.
  final int page;

  /// How many products match the filters on all pages.
  final int totalCount;

  /// The slider's limits: the cheapest and priciest product, in whole
  /// dollars. Null when there are no products.
  final PriceRange? priceBounds;

  /// The part of the slider the customer selected.
  final PriceRange? selectedPrice;

  final List<String> categories;

  /// The selected category chip, or null for "All".
  final String? selectedCategory;

  final String? errorMessage;

  bool get isLoading => status == ShopStatus.loading;

  int get totalPages => pagesFor(totalCount);
  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => page < totalPages;

  /// Position of the first and last product on this page, such as 7 and 12.
  int get firstShown => products.isEmpty ? 0 : (page - 1) * pageSize + 1;
  int get lastShown => products.isEmpty ? 0 : firstShown + products.length - 1;

  /// The price filter for the Supabase query. It is null while the slider
  /// covers every price, so a new product priced above the old maximum is
  /// not hidden.
  PriceRange? get priceFilter {
    final selected = selectedPrice;
    final bounds = priceBounds;
    if (selected == null || bounds == null || selected.covers(bounds)) {
      return null;
    }
    return selected;
  }

  bool get hasFilters => priceFilter != null || selectedCategory != null;

  ShopState copyWith({
    ShopStatus? status,
    List<Product>? products,
    int? page,
    int? totalCount,
    PriceRange? priceBounds,
    PriceRange? selectedPrice,
    bool clearPrices = false,
    List<String>? categories,
    String? selectedCategory,
    bool clearCategory = false,
    String? errorMessage,
    bool clearError = false,
  }) => ShopState(
    status: status ?? this.status,
    products: products ?? this.products,
    page: page ?? this.page,
    totalCount: totalCount ?? this.totalCount,
    priceBounds: clearPrices ? null : priceBounds ?? this.priceBounds,
    selectedPrice: clearPrices ? null : selectedPrice ?? this.selectedPrice,
    categories: categories ?? this.categories,
    selectedCategory: clearCategory
        ? null
        : selectedCategory ?? this.selectedCategory,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
