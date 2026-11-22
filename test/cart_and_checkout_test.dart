import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/app_exception.dart';
import 'package:my_first_flutter_ui/models/cart.dart';
import 'package:my_first_flutter_ui/models/order.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/providers/cart_provider.dart';
import 'package:my_first_flutter_ui/providers/catalog_providers.dart';
import 'package:my_first_flutter_ui/providers/order_providers.dart';

import 'support/containers.dart';
import 'support/fake_backend.dart';

void main() {
  late FakeBackend backend;
  late ProviderContainer container;

  setUp(() async {
    backend = FakeBackend(signedInAs: ana);
    container = await openContainer(backend);
  });

  CartNotifier cart() => container.read(cartProvider.notifier);
  Cart lines() => container.read(cartProvider);
  Product product(String name) => backend.product(name);
  Map<String, int> quantities() => {
    for (final line in lines().lines) line.product.name: line.quantity,
  };

  group('cart', () {
    test('shows a running total and item count', () {
      cart().add(product('Chef Knife'));
      cart().add(product('Chef Knife'));
      cart().add(product('Bento Box'));
      expect(quantities(), {'Chef Knife': 2, 'Bento Box': 1});
      expect(lines().itemCount, 3);
      expect(lines().total, 146);
    });

    test('the total has no rounding errors', () {
      Product at(int id, double price) => Product(
        id: id,
        name: '$id',
        price: price,
        stock: 99,
        categoryId: 1,
        categoryName: 'Audio',
      );
      final cart = Cart([
        CartLine(product: at(1, 0.1), quantity: 3),
        CartLine(product: at(2, 19.99), quantity: 3),
      ]);
      expect(cart.total, 60.27);
    });

    test('out-of-stock products cannot be added', () {
      expect(
        cart().add(product('Trail Watch')),
        'Trail Watch is out of stock.',
      );
      expect(lines().isEmpty, isTrue);
    });

    test('a quantity above the stock is refused', () {
      expect(
        cart().add(product('Studio Mic'), quantity: 3),
        contains('Only 2'),
      );
      expect(lines().isEmpty, isTrue);

      expect(cart().add(product('Studio Mic'), quantity: 2), isNull);
      expect(
        cart().add(product('Studio Mic')),
        'Only 2 of Studio Mic left, and 2 are already in your cart.',
      );
      expect(
        cart().setQuantity(product('Studio Mic'), 3),
        'Only 2 of Studio Mic left.',
      );
      expect(quantities(), {'Studio Mic': 2});
    });

    test('quantities change, and products can be removed', () {
      cart().add(product('Chef Knife'));
      cart().add(product('Power Bank'));
      cart().setQuantity(product('Chef Knife'), 5);
      expect(quantities(), {'Chef Knife': 5, 'Power Bank': 1});
      cart().remove(product('Power Bank'));
      expect(quantities(), {'Chef Knife': 5});
      cart().setQuantity(product('Chef Knife'), 0);
      expect(lines().isEmpty, isTrue);
    });

    test('it survives when no screen is watching it', () async {
      final screen = container.listen(cartProvider, (_, _) {});
      cart().add(product('Chef Knife'));
      screen.close();
      await settle();
      expect(quantities(), {'Chef Knife': 1});
    });

    test('signing out empties it', () async {
      cart().add(product('Chef Knife'));
      backend.signOut();
      await settle();
      expect(lines().isEmpty, isTrue);

      backend.signIn(ana);
      await settle();
      expect(lines().isEmpty, isTrue);
    });

    test('the next person does not get it', () async {
      cart().add(product('Chef Knife'));
      backend.signIn(ben);
      await settle();
      expect(lines().isEmpty, isTrue);
    });

    test('a token refresh keeps it', () async {
      cart().add(product('Chef Knife'));
      backend.refreshToken();
      await settle();
      expect(quantities(), {'Chef Knife': 1});
    });

    test('opening the cart loads current prices and stock', () async {
      cart().add(product('Chef Knife'), quantity: 5);
      cart().add(product('Power Bank'), quantity: 2);
      cart().add(product('Fit Band'));
      cart().add(product('Brew Kit'));
      backend
        ..change('Chef Knife', price: 70, stock: 3)
        ..change('Fit Band', stock: 0)
        ..removeProduct('Brew Kit');

      final changes = await cart().refresh();
      expect(quantities(), {'Chef Knife': 3, 'Power Bank': 2});
      expect(lines().total, 300);
      expect(changes, [
        'Only 3 of Chef Knife left, so your cart now has 3.',
        'Chef Knife now costs \$70.00.',
        'Fit Band is out of stock and was removed.',
        'Brew Kit is no longer sold and was removed.',
      ]);
    });

    test('something added while prices load is kept', () async {
      cart().add(product('Chef Knife'));
      final gate = backend.gates['fetchByIds'] = Completer();
      final refresh = cart().refresh();
      cart().add(product('Power Bank'));
      gate.complete();
      expect(await refresh, isEmpty);
      expect(quantities(), {'Chef Knife': 1, 'Power Bank': 1});
    });

    test("a late price check never fills the next person's cart", () async {
      cart().add(product('Chef Knife'));
      final gate = backend.gates['fetchByIds'] = Completer();
      final refresh = cart().refresh();
      await settle();
      backend.signIn(ben);
      await settle();
      gate.complete();
      expect(await refresh, isEmpty);
      expect(lines().isEmpty, isTrue);
    });

    test('a failed price check leaves the cart alone', () async {
      cart().add(product('Chef Knife'));
      backend.errors['fetchByIds'] = offline;
      await expectLater(cart().refresh(), throwsA(offline));
      expect(quantities(), {'Chef Knife': 1});
    });
  });

  group('checkout', () {
    CheckoutNotifier checkout() => container.read(checkoutProvider.notifier);
    AsyncValue<Order?> state() => container.read(checkoutProvider);

    test('saves the order, lowers the stock, and empties the cart', () async {
      cart().add(product('Chef Knife'), quantity: 2);
      final order = await checkout().placeOrder();

      expect(order!.status, OrderStatus.done);
      expect(order.total, 128);
      expect(order.number, '#00001');
      expect(lines().isEmpty, isTrue);
      expect(product('Chef Knife').stock, 11);
      expect(await container.read(myOrdersProvider.future), hasLength(1));
    });

    test("the database's price counts, not the one in the cart", () async {
      cart().add(product('Chef Knife'));
      backend.change('Chef Knife', price: 99, newName: 'Chef Knife Pro');
      final order = await checkout().placeOrder();
      expect(order!.total, 99);
      expect(order.items.single.productName, 'Chef Knife Pro');
    });

    test('when it fails, nothing is saved and the cart is kept', () async {
      cart().add(product('Chef Knife'));
      cart().add(product('Studio Mic'), quantity: 2);
      backend.change('Studio Mic', stock: 1); // Someone else bought one.

      expect(await checkout().placeOrder(), isNull);
      expect(messageFor(state().error!), 'Only 1 left of Studio Mic.');
      expect(backend.orders, isEmpty);
      expect(product('Chef Knife').stock, 13);
      // The cart now shows what is left, and the message stays readable.
      expect(quantities(), {'Chef Knife': 1, 'Studio Mic': 1});
      await settle();
      expect(state().hasError, isTrue);
    });

    test('changing the cart clears an old checkout error', () async {
      cart().add(product('Studio Mic'), quantity: 2);
      backend.change('Studio Mic', stock: 1);
      await checkout().placeOrder();
      expect(state().hasError, isTrue);

      cart().remove(product('Studio Mic'));
      await settle();
      expect(state().hasError, isFalse);
    });

    test('without internet the cart is kept', () async {
      cart().add(product('Chef Knife'));
      backend.errors['placeOrder'] = offline;
      expect(await checkout().placeOrder(), isNull);
      expect(quantities(), {'Chef Knife': 1});
      expect(messageFor(state().error!), 'Could not reach Supabase.');

      backend.errors.clear();
      expect(await checkout().placeOrder(), isNotNull);
      expect(lines().isEmpty, isTrue);
    });

    test('pressing Checkout twice orders once', () async {
      cart().add(product('Chef Knife'));
      final both = await Future.wait([
        checkout().placeOrder(),
        checkout().placeOrder(),
      ]);
      expect(both.whereType<Order>(), hasLength(1));
      expect(backend.orders, hasLength(1));
    });

    test('an empty cart cannot be ordered', () async {
      expect(await checkout().placeOrder(), isNull);
      expect(backend.calls, isNot(contains('placeOrder')));
    });

    test(
      "signing out meanwhile never touches the next person's cart",
      () async {
        cart().add(product('Chef Knife'));
        final gate = backend.gates['placeOrder'] = Completer();
        final pending = checkout().placeOrder();
        await settle();
        backend.signIn(ben);
        await settle();
        cart().add(product('Power Bank'));

        gate.complete();
        expect(await pending, isNull);
        expect(quantities(), {'Power Bank': 1});
        expect(state().isLoading, isFalse);
      },
    );

    test('an admin account is refused', () async {
      cart().add(product('Chef Knife'));
      backend.setRole(ana, boss.role);
      expect(await checkout().placeOrder(), isNull);
      expect(errorKindOf(state().error!), AppErrorKind.permissionDenied);
      expect(backend.orders, isEmpty);
    });

    test('the product list shows the new stock', () async {
      container.listen(productPageProvider, (_, _) {});
      await container.read(productPageProvider.future);
      cart().add(product('Steel Tumbler'), quantity: 5);
      await checkout().placeOrder();
      final page = await container.read(productPageProvider.future);
      expect(
        page.products.firstWhere((p) => p.name == 'Steel Tumbler').stock,
        40,
      );
    });
  });

  group('order history', () {
    test("lists only the customer's own orders, newest first", () async {
      Future<void> order(String name) async {
        cart().add(product(name));
        await container.read(checkoutProvider.notifier).placeOrder();
      }

      await order('Chef Knife');
      backend.signIn(ben);
      await settle();
      await order('Fit Band');
      backend.signIn(ana);
      await settle();
      await order('Power Bank');

      final orders = await container.read(myOrdersProvider.future);
      expect(orders.map((o) => o.number), ['#00003', '#00001']);
    });

    test('past orders keep the name and price that were paid', () async {
      cart().add(product('Chef Knife'));
      await container.read(checkoutProvider.notifier).placeOrder();
      backend.change('Chef Knife', price: 500, newName: 'Renamed');
      backend.removeProduct('Renamed');
      container.invalidate(myOrdersProvider);
      final order = (await container.read(myOrdersProvider.future)).single;
      expect(order.items.single.productName, 'Chef Knife');
      expect(order.items.single.unitPrice, 64);
    });
  });
}
