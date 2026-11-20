import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/data/product_repository.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/state/shop_cubit.dart';
import 'package:my_first_flutter_ui/state/shop_state.dart';

import 'support/fake_product_repository.dart';

void main() {
  late FakeProductRepository repository;
  late ShopCubit cubit;

  setUp(() {
    repository = FakeProductRepository();
    cubit = ShopCubit(repository: repository);
  });
  tearDown(() => cubit.close());

  List<String> names() => cubit.state.products.map((p) => p.name).toList();

  test('loads the first 6 products, the slider bounds, and the categories', () async {
    await cubit.load();

    final state = cubit.state;
    expect(state.status, ShopStatus.success);
    expect(names(), [
      'Bento Box',
      'Steel Tumbler',
      'Slide Sandals',
      'Laptop Sleeve',
      'Wireless Charger',
      'Cloud Pillow',
    ]);
    expect(state.totalCount, 24);
    expect(state.totalPages, 4);
    expect(state.priceBounds, const PriceRange(18, 249));
    expect(state.selectedPrice, const PriceRange(18, 249));
    expect(state.categories, [
      'Audio',
      'Bags',
      'Footwear',
      'Home',
      'Kitchen',
      'Tech',
      'Wearables',
    ]);
    // A slider covering every price sends no price filter at all.
    expect(repository.pageRequests.single, (
      page: 1,
      price: null,
      category: null,
    ));
  });

  test('each page is its own query with the next 6 products', () async {
    await cubit.load();

    await cubit.goToPage(2);
    expect(names(), [
      'Transit Sling',
      'Aroma Diffuser',
      'Power Bank',
      'Glow Desk Lamp',
      'Fit Band',
      'Brew Kit',
    ]);
    expect([cubit.state.firstShown, cubit.state.lastShown], [7, 12]);
    expect(cubit.state.hasPreviousPage, isTrue);
    expect(cubit.state.hasNextPage, isTrue);

    await cubit.goToPage(4);
    expect(names(), [
      'Weekender Duffel',
      'Aurora Headphones',
      'Trail Runners',
      'Studio Mic',
      'Pulse Watch',
      'Trail Watch',
    ]);
    expect(cubit.state.hasNextPage, isFalse);

    // Pages that don't exist are ignored.
    await cubit.goToPage(5);
    await cubit.goToPage(0);
    expect(cubit.state.page, 4);
    expect(repository.pageRequests.map((r) => r.page), [1, 2, 4]);
  });

  test('the price slider filters in the query and goes back to page 1', () async {
    await cubit.load();
    await cubit.goToPage(3);

    await cubit.setPriceRange(const PriceRange(40, 130));
    expect(cubit.state.page, 1);
    expect(cubit.state.totalCount, 13);
    expect(cubit.state.totalPages, 3);
    expect(names(), [
      'Aroma Diffuser',
      'Power Bank',
      'Glow Desk Lamp',
      'Fit Band',
      'Brew Kit',
      'Echo Mini Speaker',
    ]);
    expect(repository.pageRequests.last, (
      page: 1,
      price: const PriceRange(40, 130),
      category: null,
    ));

    await cubit.goToPage(3);
    expect(names(), ['Aurora Headphones']);
    expect([cubit.state.firstShown, cubit.state.lastShown], [13, 13]);
  });

  test('category and price filters combine, and clearing them shows everything', () async {
    await cubit.load();

    await cubit.selectCategory('Audio');
    expect(names(), [
      'Echo Mini Speaker',
      'Pulse Earbuds',
      'Aurora Headphones',
      'Studio Mic',
    ]);
    await cubit.setPriceRange(const PriceRange(60, 140));
    expect(names(), ['Pulse Earbuds', 'Aurora Headphones']);
    expect(cubit.state.hasFilters, isTrue);

    await cubit.clearFilters();
    expect(cubit.state.totalCount, 24);
    expect(cubit.state.selectedCategory, isNull);
    expect(cubit.state.priceFilter, isNull);
    expect(cubit.state.hasFilters, isFalse);
  });

  test('deleting the only product on the last page moves back a page', () async {
    await cubit.load();
    await cubit.setPriceRange(const PriceRange(40, 130));
    await cubit.goToPage(3);

    final error = await cubit.deleteProduct(
      repository.byName('Aurora Headphones'),
    );

    expect(error, isNull);
    expect(cubit.state.page, 2);
    expect(cubit.state.totalCount, 12);
    expect(cubit.state.hasNextPage, isFalse);
    expect(names(), hasLength(6));
    expect(cubit.state.selectedPrice, const PriceRange(40, 130));
  });

  test('a new top price widens a full slider but keeps a narrowed one', () async {
    await cubit.load();

    await cubit.addProduct(
      const ProductDraft(
        name: 'Studio Monitor',
        description: '',
        category: 'Audio',
        price: 499.99,
      ),
    );
    expect(cubit.state.priceBounds, const PriceRange(18, 500));
    expect(cubit.state.selectedPrice, const PriceRange(18, 500));
    expect(cubit.state.totalCount, 25);

    await cubit.setPriceRange(const PriceRange(40, 130));
    await cubit.addProduct(
      const ProductDraft(
        name: 'Sticker Pack',
        description: '',
        category: 'Home',
        price: 5,
      ),
    );
    expect(cubit.state.priceBounds, const PriceRange(5, 500));
    expect(cubit.state.selectedPrice, const PriceRange(40, 130));
  });

  test('editing a price re-sorts the product and updates the bounds', () async {
    await cubit.load();
    final trailWatch = repository.byName('Trail Watch');

    final error = await cubit.updateProduct(
      trailWatch,
      ProductDraft(
        name: trailWatch.name,
        description: trailWatch.description,
        category: trailWatch.category,
        price: 15,
      ),
    );

    expect(error, isNull);
    expect(cubit.state.priceBounds, const PriceRange(15, 199));
    expect(names().first, 'Trail Watch');
  });

  test('deleting the last product of a category, then of the shop', () async {
    final shop = FakeProductRepository(
      products: const [
        Product(id: 1, name: 'Yo-yo', description: '', category: 'Toys', price: 4),
        Product(id: 2, name: 'Atlas', description: '', category: 'Books', price: 30),
      ],
    );
    final small = ShopCubit(repository: shop);
    addTearDown(small.close);
    await small.load();
    await small.selectCategory('Toys');

    await small.deleteProduct(shop.byName('Yo-yo'));
    expect(small.state.selectedCategory, isNull);
    expect(small.state.categories, ['Books']);
    expect(small.state.products.map((p) => p.name), ['Atlas']);

    await small.deleteProduct(shop.byName('Atlas'));
    expect(small.state.status, ShopStatus.success);
    expect(small.state.products, isEmpty);
    expect(small.state.totalCount, 0);
    expect(small.state.priceBounds, isNull);
    expect(small.state.selectedPrice, isNull);
  });

  test('a failed page keeps the filters, and load() retries it', () async {
    await cubit.load();
    await cubit.setPriceRange(const PriceRange(40, 130));
    repository.error = const ProductRepositoryException('Offline');

    await cubit.goToPage(2);
    expect(cubit.state.status, ShopStatus.failure);
    expect(cubit.state.errorMessage, 'Offline');
    expect(cubit.state.page, 2);
    expect(cubit.state.selectedPrice, const PriceRange(40, 130));

    repository.error = null;
    await cubit.load();
    expect(cubit.state.status, ShopStatus.success);
    expect(cubit.state.errorMessage, isNull);
    expect(names().first, 'Chef Knife');
  });

  test('a failed save returns its message and leaves the list alone', () async {
    await cubit.load();
    final before = cubit.state;
    repository.error = const ProductRepositoryException('Blocked by RLS.');

    final error = await cubit.deleteProduct(repository.byName('Bento Box'));

    expect(error, 'Blocked by RLS.');
    expect(cubit.state, same(before));
    expect(repository.products, hasLength(24));
  });

  test('a slow older page never replaces a newer one', () async {
    await cubit.load();
    final page2 = Completer<void>();
    repository.beforePage = (page) => page == 2 ? page2.future : Future.value();

    final slow = cubit.goToPage(2);
    await cubit.goToPage(3);
    page2.complete();
    await slow;

    expect(cubit.state.page, 3);
    expect(names().first, 'Echo Mini Speaker');
  });

  test('closing while a page loads does not emit afterwards', () async {
    await cubit.load();
    final gate = Completer<void>();
    repository.beforePage = (_) => gate.future;

    final pending = cubit.goToPage(2);
    await cubit.close();
    gate.complete();
    // This would throw a StateError if the Cubit emitted after close().
    await pending;
  });
}
