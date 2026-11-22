import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/app_exception.dart';
import 'package:my_first_flutter_ui/models/catalog.dart';
import 'package:my_first_flutter_ui/models/category.dart';
import 'package:my_first_flutter_ui/models/order.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/providers/admin_providers.dart';
import 'package:my_first_flutter_ui/providers/cart_provider.dart';
import 'package:my_first_flutter_ui/providers/catalog_providers.dart';
import 'package:my_first_flutter_ui/providers/order_providers.dart';
import 'package:my_first_flutter_ui/providers/session_providers.dart';

import 'support/containers.dart';
import 'support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late ProviderContainer container;

  Future<void> open(FakeBackend newBackend) async {
    backend = newBackend;
    container = await openContainer(backend);
    container
      ..listen(productPageProvider, (_, _) {})
      ..listen(priceBoundsProvider, (_, _) {})
      ..listen(categoriesProvider, (_, _) {});
    await container.read(priceBoundsProvider.future);
    await container.read(categoriesProvider.future);
    await container.read(productPageProvider.future);
  }

  CatalogFiltersNotifier filters() =>
      container.read(catalogFiltersProvider.notifier);
  Future<ProductPage> page() => container.read(productPageProvider.future);
  Future<List<String>> names() async => [
    for (final product in (await page()).products) product.name,
  ];

  group('browsing and filtering', () {
    setUp(() => open(FakeBackend(signedInAs: ana)));

    test('6 products per page, cheapest first', () async {
      expect(await names(), [
        'Bento Box',
        'Steel Tumbler',
        'Slide Sandals',
        'Laptop Sleeve',
        'Wireless Charger',
        'Cloud Pillow',
      ]);
      expect((await page()).totalPages, 4);

      filters().goToPage(4);
      expect((await names()).last, 'Trail Watch');
      expect((await page()).firstShown, 19);
      expect((await page()).lastShown, 24);
    });

    test('the slider limits are whole dollars', () async {
      expect(
        await container.read(priceBoundsProvider.future),
        const PriceRange(18, 249),
      );
    });

    test('price, category, and search combine and go back to page 1', () async {
      filters().goToPage(3);
      await page();
      filters().selectPrice(const PriceRange(40, 130));
      expect((await page()).totalCount, 13);
      expect((await page()).page, 1);

      final audio = backend.categories.firstWhere((c) => c.name == 'Audio');
      filters().selectCategory(audio.id);
      expect(await names(), [
        'Echo Mini Speaker',
        'Pulse Earbuds',
        'Aurora Headphones',
      ]);

      filters().search('  pulse ');
      expect(await names(), ['Pulse Earbuds']);
      expect(
        backend.pageRequests.last,
        CatalogFilters(
          search: 'pulse',
          categoryId: audio.id,
          price: const PriceRange(40, 130),
        ),
      );

      filters().clear();
      expect((await page()).totalCount, 24);
    });

    test('a slider over every price sends no price filter', () async {
      filters().selectPrice(const PriceRange(18, 249));
      await page();
      expect(container.read(catalogFiltersProvider).price, isNull);
    });

    test(
      'the newest choice wins, even if an older query answers last',
      () async {
        final slow = backend.gates['fetchPage'] = Completer();
        filters().goToPage(2);
        await settle();
        backend.gates.remove('fetchPage');
        filters().goToPage(3);
        expect((await names()).first, 'Echo Mini Speaker');

        slow.complete();
        await settle();
        expect(
          container.read(productPageProvider).requireValue.products.first.name,
          'Echo Mini Speaker',
        );
      },
    );

    test('an error shows at once, without silent retries', () async {
      backend.errors['fetchPage'] = offline;
      container.invalidate(productPageProvider);
      await settle();
      final value = container.read(productPageProvider);
      expect(value.hasError && !value.isLoading, isTrue);
      final calls = backend.calls.length;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(backend.calls, hasLength(calls));

      backend.errors.clear();
      refreshCatalog(container.invalidate);
      expect(await names(), hasLength(6));
    });

    test('the next person starts without filters', () async {
      filters().search('pulse');
      backend.signIn(ben);
      await settle();
      expect(container.read(catalogFiltersProvider), const CatalogFilters());
    });

    test('signed out, nothing is asked of the database', () async {
      backend.signOut();
      await settle();
      backend.calls.clear();
      expect((await page()).products, isEmpty);
      expect(await container.read(categoriesProvider.future), isEmpty);
      expect(await container.read(priceBoundsProvider.future), isNull);
      expect(backend.calls, isEmpty);
    });
  });

  const draft = ProductDraft(
    name: 'Desk Mat',
    description: 'Soft felt.',
    price: 12.5,
    stock: 3,
    categoryId: 4,
  );

  group('admin: products', () {
    setUp(() => open(FakeBackend(signedInAs: boss)));

    ProductSaveNotifier saver() => container.read(productSaveProvider.notifier);

    test('adding shows up in the list and the slider limits', () async {
      expect(await saver().save(draft), isNull);
      expect((await names()).first, 'Desk Mat');
      expect(
        await container.read(priceBoundsProvider.future),
        const PriceRange(12, 249),
      );
    });

    test('a picture is uploaded first and saved with the product', () async {
      await saver().save(draft, newImage: tinyPng);
      final saved = backend.product('Desk Mat');
      expect(saved.imagePath, isNotNull);
      expect(backend.images, {saved.imagePath});
    });

    test('a new picture replaces the old one', () async {
      await saver().save(draft, newImage: tinyPng);
      final before = backend.product('Desk Mat');
      await saver().save(draft, existing: before, newImage: tinyPng);
      final after = backend.product('Desk Mat');
      expect(after.imagePath, isNot(before.imagePath));
      expect(backend.images, {after.imagePath});
    });

    test('editing without touching the picture keeps it', () async {
      await saver().save(draft, newImage: tinyPng);
      final before = backend.product('Desk Mat');
      await saver().save(draft, existing: before);
      expect(backend.product('Desk Mat').imagePath, before.imagePath);
      expect(backend.images, {before.imagePath});
    });

    test('a picture can be removed', () async {
      await saver().save(draft, newImage: tinyPng);
      await saver().save(
        draft,
        existing: backend.product('Desk Mat'),
        removeImage: true,
      );
      expect(backend.product('Desk Mat').imagePath, isNull);
      expect(backend.images, isEmpty);
    });

    test('when saving fails, the uploaded picture is removed again', () async {
      backend.errors['createProduct'] = offline;
      expect(await saver().save(draft, newImage: tinyPng), offline);
      expect(backend.images, isEmpty);
      expect(backend.products, hasLength(24));
    });

    test('a failed picture clean-up does not count as a failed save', () async {
      await saver().save(draft, newImage: tinyPng);
      backend.errors['deleteImage'] = offline;
      expect(
        await saver().save(
          draft,
          existing: backend.product('Desk Mat'),
          newImage: tinyPng,
        ),
        isNull,
      );
    });

    test('the save finishes even if its page was closed', () async {
      final screen = container.listen(productSaveProvider, (_, _) {});
      final pending = saver().save(draft);
      screen.close();
      expect(await pending, isNull);
      expect((await names()).first, 'Desk Mat');
    });

    test('pressing Save twice saves once', () async {
      container.listen(productSaveProvider, (_, _) {});
      final results = await Future.wait([
        saver().save(draft),
        saver().save(draft),
      ]);
      expect(results.where((error) => error == null), hasLength(1));
      expect(backend.products, hasLength(25));
    });

    test(
      'deleting the only product of the last page shows the page before',
      () async {
        await saver().save(
          const ProductDraft(
            name: 'Gold Watch',
            description: '',
            price: 999,
            stock: 1,
            categoryId: 7,
          ),
        );
        filters().goToPage(5);
        expect(await names(), ['Gold Watch']);
        await container
            .read(productDeleteProvider.notifier)
            .delete(backend.product('Gold Watch'));
        final shown = await page();
        expect(shown.page, 4);
        expect(shown.products, hasLength(6));
      },
    );

    test('deleting a product also deletes its picture', () async {
      await saver().save(draft, newImage: tinyPng);
      await container
          .read(productDeleteProvider.notifier)
          .delete(backend.product('Desk Mat'));
      expect(backend.images, isEmpty);
    });
  });

  group('admin: categories and orders', () {
    setUp(() => open(FakeBackend(signedInAs: boss)));

    test('add, rename, and delete', () async {
      final saver = container.read(categorySaveProvider.notifier);
      expect(await saver.save('Garden'), isNull);
      var all = await container.read(categoriesProvider.future);
      final garden = all.firstWhere((c) => c.name == 'Garden');
      expect(
        await container
            .read(categorySaveProvider.notifier)
            .save('Outdoor', existing: garden),
        isNull,
      );
      final outdoor = Category(id: garden.id, name: 'Outdoor');
      expect(
        await container.read(categoryDeleteProvider.notifier).delete(outdoor),
        isNull,
      );
      all = await container.read(categoriesProvider.future);
      expect(all.map((c) => c.name), isNot(contains('Outdoor')));
    });

    test('renaming updates the product cards', () async {
      final kitchen = backend.categories.firstWhere((c) => c.name == 'Kitchen');
      await container
          .read(categorySaveProvider.notifier)
          .save('Cooking', existing: kitchen);
      expect((await page()).products.first.categoryName, 'Cooking');
    });

    test('a category with products is kept, with the reason', () async {
      final error = await container
          .read(categoryDeleteProvider.notifier)
          .delete(backend.categories.first);
      expect(messageFor(error!), contains('still has products'));
    });

    test('deleting the filtered category clears that filter', () async {
      await container.read(categorySaveProvider.notifier).save('Garden');
      final garden = backend.categories.last;
      filters().selectCategory(garden.id);
      expect((await page()).totalCount, 0);
      await container.read(categoryDeleteProvider.notifier).delete(garden);
      expect(container.read(catalogFiltersProvider).categoryId, isNull);
      expect((await page()).totalCount, 24);
    });

    test('admins see every order and change its status', () async {
      backend.signIn(ana);
      await settle();
      container.read(cartProvider.notifier).add(backend.product('Chef Knife'));
      await container.read(checkoutProvider.notifier).placeOrder();
      backend.signIn(boss);
      await settle();

      var orders = await container.read(allOrdersProvider.future);
      expect(orders.single.customerName, 'Ana Cruz');
      final error = await container
          .read(orderStatusProvider.notifier)
          .update(orders.single, OrderStatus.processing);
      expect(error, isNull);
      orders = await container.read(allOrdersProvider.future);
      expect(orders.single.status, OrderStatus.processing);
      expect(container.read(orderStatusProvider), isNull);
    });
  });

  group('a customer is refused by the database', () {
    setUp(() => open(FakeBackend(signedInAs: ana)));

    test('even if the app called the admin actions', () async {
      final chefKnife = backend.product('Chef Knife');
      final results = [
        await container.read(productSaveProvider.notifier).save(draft),
        await container
            .read(productSaveProvider.notifier)
            .save(draft, existing: chefKnife),
        await container
            .read(productSaveProvider.notifier)
            .save(draft, newImage: tinyPng),
        await container.read(productDeleteProvider.notifier).delete(chefKnife),
        await container.read(categorySaveProvider.notifier).save('Garden'),
        await container
            .read(categoryDeleteProvider.notifier)
            .delete(backend.categories.first),
      ];
      expect(results, everyElement(permissionDenied));
      expect(backend.products, hasLength(24));
      expect(backend.categories, hasLength(7));
      expect(backend.images, isEmpty);

      await expectLater(
        container.read(allOrdersProvider.future),
        throwsA(permissionDenied),
      );
    });

    test('and an admin cannot edit a profile', () async {
      await open(FakeBackend(signedInAs: boss));
      final error = await container
          .read(profileSaveProvider.notifier)
          .saveName(firstName: 'X', lastName: 'Y');
      expect(error, permissionDenied);
    });
  });
}
