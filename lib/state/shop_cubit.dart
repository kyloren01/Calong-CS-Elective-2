import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/product_repository.dart';
import '../models/product.dart';
import 'shop_state.dart';

/// Owns the shop's state. Every page, slider, or category change becomes a
/// new Supabase query, so the app only ever downloads one page of products.
class ShopCubit extends Cubit<ShopState> {
  ShopCubit({required this.repository}) : super(const ShopState());

  final ProductRepository repository;

  // Every request gets a number, and only the newest one may change the
  // state. That way a slow page 2 can't replace page 3 if it answers last.
  int _latestRequest = 0;

  /// First load, refresh, and retry. Also reloads the slider bounds and the
  /// categories, because adding, editing, or deleting can change them.
  Future<void> load() async {
    if (isClosed) return;
    final request = ++_latestRequest;
    emit(state.copyWith(status: ShopStatus.loading, clearError: true));
    try {
      final results = await Future.wait<Object?>([
        repository.fetchPriceBounds(),
        repository.fetchCategories(),
      ]);
      final prices = results[0] as PriceRange?;
      final categories = results[1] as List<String>;
      final bounds = prices == null ? null : PriceRange.wholeDollars(prices);
      final category = categories.contains(state.selectedCategory)
          ? state.selectedCategory
          : null;
      final query = state.copyWith(
        priceBounds: bounds,
        selectedPrice: _keepSelection(
          state.priceBounds,
          state.selectedPrice,
          bounds,
        ),
        clearPrices: bounds == null,
        categories: categories,
        clearCategory: category == null,
      );
      await _showPage(query, request);
    } catch (error) {
      _fail(error, request);
    }
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || page > state.totalPages || page == state.page) return;
    await _refresh(state.copyWith(page: page));
  }

  /// Selects a category chip; null means "All". Goes back to page 1.
  Future<void> selectCategory(String? category) => _refresh(
    state.copyWith(
      page: 1,
      selectedCategory: category,
      clearCategory: category == null,
    ),
  );

  /// Applies the range chosen on the price slider. Goes back to page 1.
  Future<void> setPriceRange(PriceRange range) =>
      _refresh(state.copyWith(page: 1, selectedPrice: range));

  Future<void> clearFilters() => _refresh(
    state.copyWith(
      page: 1,
      selectedPrice: state.priceBounds,
      clearCategory: true,
    ),
  );

  /// Returns null when the product was saved, or a message saying why not.
  Future<String?> addProduct(ProductDraft draft) =>
      _change(() => repository.createProduct(draft));

  Future<String?> updateProduct(Product product, ProductDraft draft) =>
      _change(() => repository.updateProduct(product.id, draft));

  Future<String?> deleteProduct(Product product) =>
      _change(() => repository.deleteProduct(product.id));

  Future<String?> _change(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      return _messageFor(error);
    }
    await load();
    return null;
  }

  Future<void> _refresh(ShopState query) async {
    if (isClosed) return;
    final request = ++_latestRequest;
    // Show the new filters and page number right away; the products follow.
    emit(query.copyWith(status: ShopStatus.loading, clearError: true));
    try {
      await _showPage(query, request);
    } catch (error) {
      _fail(error, request);
    }
  }

  /// Fetches the page [query] asks for and shows it, unless a newer request
  /// started meanwhile.
  Future<void> _showPage(ShopState query, int request) async {
    var page = query.page;
    var result = await _fetch(query, page);
    // The page may no longer exist, for example after its only product was
    // deleted. Show the new last page instead.
    final lastPage = ShopState.pagesFor(result.totalCount);
    if (page > lastPage) {
      page = lastPage;
      result = await _fetch(query, page);
    }
    if (_isStale(request)) return;
    emit(
      query.copyWith(
        status: ShopStatus.success,
        products: result.products,
        page: page,
        totalCount: result.totalCount,
        clearError: true,
      ),
    );
  }

  Future<ProductPage> _fetch(ShopState query, int page) =>
      repository.fetchProducts(
        page: page,
        pageSize: ShopState.pageSize,
        price: query.priceFilter,
        category: query.selectedCategory,
      );

  void _fail(Object error, int request) {
    if (_isStale(request)) return;
    emit(
      state.copyWith(
        status: ShopStatus.failure,
        errorMessage: _messageFor(error),
      ),
    );
  }

  bool _isStale(int request) => isClosed || request != _latestRequest;

  static String _messageFor(Object error) =>
      error is ProductRepositoryException
      ? error.message
      : 'Something went wrong: $error';

  /// Keeps the customer's slider selection when the bounds change. If the
  /// selection covered every price, it grows or shrinks with the new bounds.
  static PriceRange? _keepSelection(
    PriceRange? oldBounds,
    PriceRange? selection,
    PriceRange? newBounds,
  ) {
    if (newBounds == null) return null;
    if (oldBounds == null || selection == null || selection.covers(oldBounds)) {
      return newBounds;
    }
    return selection.clampTo(newBounds);
  }
}
