import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../models/catalog.dart';
import '../models/category.dart';
import 'service_providers.dart';
import 'session_providers.dart';

/// The search text, category, price range, and page the person chose.
final catalogFiltersProvider =
    NotifierProvider<CatalogFiltersNotifier, CatalogFilters>(
      CatalogFiltersNotifier.new,
    );

class CatalogFiltersNotifier extends Notifier<CatalogFilters> {
  @override
  CatalogFilters build() {
    ref.watch(userIdProvider);
    return const CatalogFilters();
  }

  // Every filter change starts again at page 1.

  void search(String text) => state = CatalogFilters(
    search: text.trim(),
    categoryId: state.categoryId,
    price: state.price,
  );

  /// Null means every category.
  void selectCategory(int? categoryId) => state = CatalogFilters(
    search: state.search,
    categoryId: categoryId,
    price: state.price,
  );

  void selectPrice(PriceRange range) {
    final bounds = ref.read(priceBoundsProvider).value;
    // A slider that covers every price means "don't filter", so a product
    // added later at a higher price isn't hidden.
    final all = bounds != null && range.covers(bounds);
    state = CatalogFilters(
      search: state.search,
      categoryId: state.categoryId,
      price: all ? null : range,
    );
  }

  void goToPage(int page) => state = CatalogFilters(
    search: state.search,
    categoryId: state.categoryId,
    price: state.price,
    page: page,
  );

  void clear() => state = const CatalogFilters();
}

/// The price slider's limits, in whole dollars. Null without products.
final priceBoundsProvider = FutureProvider<PriceRange?>((ref) async {
  if (ref.watch(userIdProvider) == null) return null;
  final prices = await ref.watch(productServiceProvider).fetchPriceBounds();
  return prices == null ? null : PriceRange.wholeDollars(prices);
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  if (ref.watch(userIdProvider) == null) return const [];
  return ref.watch(categoryServiceProvider).fetchAll();
});

/// The current page of products. Changing a filter runs a new Supabase
/// query; Riverpod drops the answer of any older query still running.
final productPageProvider = FutureProvider<ProductPage>((ref) async {
  final filters = ref.watch(catalogFiltersProvider);
  if (ref.watch(userIdProvider) == null) {
    return const ProductPage(products: [], totalCount: 0, page: 1);
  }
  return ref.watch(productServiceProvider).fetchPage(filters);
});

/// Loads the products, slider limits, and categories again. Pass it
/// `ref.invalidate`.
void refreshCatalog(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(productPageProvider);
  invalidate(priceBoundsProvider);
  invalidate(categoriesProvider);
}
