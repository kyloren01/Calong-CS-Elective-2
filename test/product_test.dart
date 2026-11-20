import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/state/shop_state.dart';
import 'package:my_first_flutter_ui/widgets/pagination_bar.dart';

void main() {
  test('Product.fromJson reads a Supabase row', () {
    final product = Product.fromJson({
      'id': 3,
      'name': 'Pulse Earbuds',
      'description': null,
      'category': 'Audio',
      'price': 89,
      'created_at': '2026-11-20T16:16:27.98+00:00',
    });

    expect(product.id, 3);
    expect(product.price, 89.0);
    expect(product.description, '');
  });

  test('slider bounds are whole dollars and never zero-width', () {
    expect(
      PriceRange.wholeDollars(const PriceRange(18.5, 249.2)),
      const PriceRange(18, 250),
    );
    expect(
      PriceRange.wholeDollars(const PriceRange(30, 30)),
      const PriceRange(30, 31),
    );
  });

  test('6 products per page', () {
    expect(ShopState.pageSize, 6);
    expect(ShopState.pagesFor(0), 1);
    expect(ShopState.pagesFor(6), 1);
    expect(ShopState.pagesFor(7), 2);
    expect(ShopState.pagesFor(24), 4);
  });

  test('the pagination bar shows at most 5 page numbers', () {
    List<int> pages(int page, int totalPages) => PaginationBar(
      page: page,
      totalPages: totalPages,
      onPageSelected: (_) {},
    ).visiblePages;

    expect(pages(1, 4), [1, 2, 3, 4]);
    expect(pages(1, 9), [1, 2, 3, 4, 5]);
    expect(pages(5, 9), [3, 4, 5, 6, 7]);
    expect(pages(9, 9), [5, 6, 7, 8, 9]);
  });
}
