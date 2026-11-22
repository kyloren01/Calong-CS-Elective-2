import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/catalog.dart';
import 'package:my_first_flutter_ui/pages/admin/product_form_page.dart';
import 'package:my_first_flutter_ui/pages/auth/login_page.dart';
import 'package:my_first_flutter_ui/pages/customer/order_confirmation_page.dart';
import 'package:my_first_flutter_ui/pages/customer/product_details_page.dart';
import 'package:my_first_flutter_ui/widgets/order_card.dart';
import 'package:my_first_flutter_ui/widgets/product_card.dart';
import 'package:my_first_flutter_ui/widgets/search_field.dart';

import 'support/app_tester.dart';
import 'support/fake_backend.dart';

void main() {
  Future<void> addToCart(WidgetTester tester, String product) =>
      tap(tester, inCard(product, find.text('Add to cart')));

  group('what a customer sees', () {
    testWidgets('products with Add to cart, and no management controls', (
      tester,
    ) async {
      await openApp(tester, signedInAs: ana);
      expect(visibleProducts(tester), [
        'Bento Box',
        'Steel Tumbler',
        'Slide Sandals',
        'Laptop Sleeve',
        'Wireless Charger',
        'Cloud Pillow',
      ]);
      expect(find.text('Add to cart'), findsNWidgets(6));

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.byTooltip('Delete Bento Box'), findsNothing);
      expect(tabs('Categories'), findsNothing);
      expect(tabs('Products'), findsNothing);
      for (final tab in ['Shop', 'Cart', 'Orders', 'Account']) {
        expect(tabs(tab), findsWidgets, reason: tab);
      }
    });

    testWidgets('the admin form is refused, even if it were opened', (
      tester,
    ) async {
      await openApp(tester, signedInAs: ana);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(builder: (_) => const ProductFormPage()),
          );
      await tester.pumpAndSettle();
      expect(find.text('Permission denied'), findsOneWidget);
      expect(field('Name'), findsNothing);
      await tap(tester, filledButton('Go back'));
      expect(find.byType(ProductFormPage), findsNothing);
    });
  });

  group('browsing and filtering', () {
    testWidgets('pages of 6 products', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      expect(
        find.text('Showing 1–6 of 24 products · Page 1 of 4'),
        findsOneWidget,
      );
      await tap(tester, find.byTooltip('Next page'));
      expect(visibleProducts(tester).first, 'Transit Sling');
      await tap(tester, find.widgetWithText(TextButton, '4'));
      expect(visibleProducts(tester).last, 'Trail Watch');
      expect(
        find.text('Showing 19–24 of 24 products · Page 4 of 4'),
        findsOneWidget,
      );
      expect(backend.pageRequests.map((f) => f.page), [1, 2, 4]);
    });

    testWidgets('the price slider filters in the query', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      final slider = tester.getRect(find.byType(RangeSlider));
      await tester.dragFrom(
        Offset(slider.left + 24, slider.center.dy),
        const Offset(120, 0),
      );
      await tester.pumpAndSettle();

      final price = backend.pageRequests.last.price!;
      expect(price.min, greaterThan(18));
      expect(price.max, 249);
      expect(find.text('\$${price.min.round()} – \$249'), findsOneWidget);
      for (final card in tester.widgetList<ProductCard>(
        find.byType(ProductCard),
      )) {
        expect(card.product.price, greaterThanOrEqualTo(price.min));
      }

      await tap(tester, find.text('Clear filters'));
      expect(backend.pageRequests.last, const CatalogFilters());
      expect(find.text('\$18 – \$249'), findsOneWidget);
    });

    testWidgets('category chips', (tester) async {
      await openApp(tester, signedInAs: ana);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Audio'));
      expect(visibleProducts(tester), [
        'Echo Mini Speaker',
        'Pulse Earbuds',
        'Aurora Headphones',
        'Studio Mic',
      ]);
      await tap(tester, find.widgetWithText(ChoiceChip, 'All'));
      expect(find.byType(ProductCard), findsNWidgets(6));
    });

    testWidgets('search waits for a pause in typing', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      for (final text in ['p', 'pu', 'pulse']) {
        await tester.enterText(find.byType(SearchField), text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(backend.pageRequests, hasLength(1));

      await tester.pump(SearchField.pause);
      await tester.pumpAndSettle();
      expect(backend.pageRequests, hasLength(2));
      expect(visibleProducts(tester), ['Pulse Earbuds', 'Pulse Watch']);

      await tap(tester, find.byTooltip('Clear search'));
      expect(find.byType(ProductCard), findsNWidgets(6));
    });

    testWidgets('no match offers to clear the filters', (tester) async {
      await openApp(tester, signedInAs: ana);
      await tester.enterText(find.byType(SearchField), 'zzz');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('No products match'), findsOneWidget);

      await tap(tester, outlinedButton('Clear filters'));
      expect(find.byType(ProductCard), findsNWidgets(6));
      expect(find.text('zzz'), findsNothing);
    });

    testWidgets('an empty shop says so', (tester) async {
      final backend = FakeBackend(signedInAs: ana)..products.clear();
      await openApp(tester, backend: backend);
      expect(find.text('No products yet'), findsOneWidget);
      expect(
        find.text('The shop has nothing for sale right now.'),
        findsOneWidget,
      );
    });

    testWidgets('errors show a reason and Try again', (tester) async {
      final backend = FakeBackend(signedInAs: ana);
      backend.errors['fetchPage'] = offline;
      await openApp(tester, backend: backend);
      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Could not reach Supabase.'), findsOneWidget);

      backend.errors.clear();
      await tap(tester, filledButton('Try again'));
      expect(find.byType(ProductCard), findsNWidgets(6));
    });

    testWidgets('a permission problem looks different from being offline', (
      tester,
    ) async {
      final backend = FakeBackend(signedInAs: ana);
      backend.errors['fetchPage'] = permissionDenied;
      await openApp(tester, backend: backend);
      expect(find.text('Permission denied'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('categories that fail to load leave the products usable', (
      tester,
    ) async {
      final backend = FakeBackend(signedInAs: ana);
      backend.errors['fetchCategories'] = offline;
      await openApp(tester, backend: backend);
      expect(find.byType(ProductCard), findsNWidgets(6));
      expect(find.text('Could not reach Supabase.'), findsOneWidget);

      backend.errors.clear();
      await tap(tester, find.text('Try again'));
      expect(find.widgetWithText(ChoiceChip, 'Audio'), findsOneWidget);
    });
  });

  group('cart', () {
    testWidgets('adding shows a message, a badge, and stops at the stock', (
      tester,
    ) async {
      await openApp(tester, signedInAs: ana);
      await addToCart(tester, 'Bento Box'); // Only one left.
      expect(find.text('Bento Box added to your cart.'), findsOneWidget);
      expect(inCard('Bento Box', find.text('1 in cart')), findsOneWidget);
      expect(
        isEnabled(tester, inCard('Bento Box', filledButton('No more left'))),
        isFalse,
      );
      expect(
        find.descendant(of: find.byType(Badge), matching: find.text('1')),
        findsWidgets,
      );
    });

    testWidgets('out-of-stock products cannot be added', (tester) async {
      await openApp(tester, signedInAs: ana);
      await tap(tester, find.widgetWithText(TextButton, '4'));
      expect(
        isEnabled(
          tester,
          inCard(
            'Trail Watch',
            find.byWidgetPredicate((w) => w is FilledButton),
          ),
        ),
        isFalse,
      );
    });

    testWidgets('the details page adds several, up to the stock', (
      tester,
    ) async {
      await openApp(tester, signedInAs: ana);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Audio'));
      await tap(tester, find.text('Studio Mic'));
      expect(find.byType(ProductDetailsPage), findsOneWidget);
      await tap(tester, find.byTooltip('Increase quantity'));
      expect(find.byTooltip('Increase quantity'), findsNothing);
      expect(find.byTooltip('No more in stock'), findsOneWidget);

      await tap(tester, filledButton('Add to cart'));
      expect(find.text('2 × Studio Mic added to your cart.'), findsOneWidget);
      expect(find.text('2 in your cart'), findsOneWidget);
      expect(isEnabled(tester, filledButton('No more left')), isFalse);
    });

    testWidgets('quantities, removing, total, and item count', (tester) async {
      await openApp(tester, signedInAs: ana);
      await addToCart(tester, 'Steel Tumbler');
      await addToCart(tester, 'Cloud Pillow');
      await openTab(tester, 'Cart');
      expect(find.text('2 items'), findsOneWidget);
      expect(find.text('\$57.00'), findsOneWidget);

      await tap(tester, find.byTooltip('Increase Steel Tumbler'));
      expect(find.text('3 items'), findsOneWidget);
      expect(find.text('\$79.00'), findsOneWidget);

      await tap(tester, find.byTooltip('Decrease Steel Tumbler'));
      await tap(tester, find.byTooltip('Remove Cloud Pillow'));
      expect(find.text('1 item'), findsOneWidget);

      await tap(tester, find.byTooltip('Remove Steel Tumbler'));
      expect(find.text('Your cart is empty'), findsOneWidget);
      await tap(tester, filledButton('Browse products'));
      expect(find.byType(ProductCard), findsNWidgets(6));
    });

    testWidgets('it survives switching screens', (tester) async {
      await openApp(tester, signedInAs: ana);
      await addToCart(tester, 'Steel Tumbler');
      await openTab(tester, 'Orders');
      await openTab(tester, 'Account');
      await openTab(tester, 'Cart');
      expect(find.text('Steel Tumbler'), findsOneWidget);
    });

    testWidgets('opening it shows what changed meanwhile', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      await addToCart(tester, 'Steel Tumbler');
      backend.change('Steel Tumbler', price: 30);
      await openTab(tester, 'Cart');
      expect(find.text('Steel Tumbler now costs \$30.00.'), findsOneWidget);
      expect(find.text('\$30.00 each'), findsOneWidget);
    });
  });

  group('checkout and orders', () {
    testWidgets('from cart to confirmation to history', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      await addToCart(tester, 'Steel Tumbler');
      await openTab(tester, 'Cart');
      await tap(tester, find.byTooltip('Increase Steel Tumbler'));
      await tap(tester, filledButton('Checkout'));

      expect(find.byType(OrderConfirmationPage), findsOneWidget);
      expect(find.text('Your order number is #00001.'), findsOneWidget);
      expect(find.text('Total: \$44.00'), findsOneWidget);
      expect(backend.product('Steel Tumbler').stock, 43);

      await tap(tester, filledButton('View my orders'));
      expect(find.byType(OrderCard), findsOneWidget);
      expect(find.text('Order #00001'), findsOneWidget);
      expect(find.text('2 × Steel Tumbler'), findsOneWidget);
      expect(find.text('\$22.00 each'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.textContaining('Nov 22, 2026'), findsOneWidget);

      await openTab(tester, 'Cart');
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('newest first', (tester) async {
      await openApp(tester, signedInAs: ana);
      for (final product in ['Steel Tumbler', 'Cloud Pillow']) {
        await openTab(tester, 'Shop');
        await addToCart(tester, product);
        await openTab(tester, 'Cart');
        await tap(tester, filledButton('Checkout'));
        await tap(tester, find.text('Keep shopping'));
      }
      await openTab(tester, 'Orders');
      expect(
        [
          for (final card in tester.widgetList<OrderCard>(
            find.byType(OrderCard),
          ))
            card.order.number,
        ],
        ['#00002', '#00001'],
      );
    });

    testWidgets('a refused order keeps the cart and says why', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      await addToCart(tester, 'Steel Tumbler');
      await openTab(tester, 'Cart');
      await tap(tester, find.byTooltip('Increase Steel Tumbler'));
      backend.change('Steel Tumbler', stock: 1);

      await tap(tester, filledButton('Checkout'));
      expect(find.byType(OrderConfirmationPage), findsNothing);
      expect(find.text('Only 1 left of Steel Tumbler.'), findsOneWidget);
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Only 1 left'), findsOneWidget);
      expect(backend.orders, isEmpty);

      await tap(tester, filledButton('Checkout'));
      expect(find.byType(OrderConfirmationPage), findsOneWidget);
    });

    testWidgets('when everything sold out, the reason is still shown', (
      tester,
    ) async {
      final backend = await openApp(tester, signedInAs: ana);
      await addToCart(tester, 'Steel Tumbler');
      await openTab(tester, 'Cart');
      backend.change('Steel Tumbler', stock: 0);
      await tap(tester, filledButton('Checkout'));
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Steel Tumbler is out of stock.'), findsOneWidget);
      await tap(tester, find.byTooltip('Dismiss'));
      expect(find.text('Steel Tumbler is out of stock.'), findsNothing);
    });

    testWidgets('no orders yet, and orders that fail to load', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      await openTab(tester, 'Orders');
      expect(find.text('No orders yet'), findsOneWidget);

      backend.errors['fetchMyOrders'] = offline;
      await tap(tester, find.byTooltip('Refresh'));
      expect(find.text('No connection'), findsOneWidget);
      backend.errors.clear();
      await tap(tester, filledButton('Try again'));
      expect(find.text('No orders yet'), findsOneWidget);
    });
  });

  group('account', () {
    testWidgets('customers can change their name', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      await openTab(tester, 'Account');
      expect(find.text('ana@example.com'), findsOneWidget);
      await tap(tester, find.text('Edit name'));
      await tester.enterText(field('First name'), '');
      await tap(tester, filledButton('Save'));
      expect(find.text('Enter your first name'), findsOneWidget);

      await tester.enterText(field('First name'), 'Anna');
      await tap(tester, filledButton('Save'));
      expect(find.text('Anna Cruz'), findsOneWidget);
      expect(find.text('Name saved.'), findsOneWidget);
      expect(backend.profiles['ana']!.role, ana.role);
    });

    testWidgets('a refused name change stays in the dialog', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      backend.errors['updateName'] = permissionDenied;
      await openTab(tester, 'Account');
      await tap(tester, find.text('Edit name'));
      await tap(tester, filledButton('Save'));
      expect(find.text(permissionDenied.message), findsOneWidget);
      expect(field('First name'), findsOneWidget);
    });

    testWidgets('signing out warns about the cart, then empties it', (
      tester,
    ) async {
      final backend = await openApp(tester, signedInAs: ana);
      await addToCart(tester, 'Steel Tumbler');
      await openTab(tester, 'Account');
      await tap(tester, outlinedButton('Sign out'));
      expect(find.textContaining('empties your cart (1 item)'), findsOneWidget);
      await tap(tester, find.text('Cancel'));
      expect(find.byType(LoginPage), findsNothing);

      await tap(tester, outlinedButton('Sign out'));
      await tap(tester, filledButton('Sign out'));
      expect(find.byType(LoginPage), findsOneWidget);

      backend.signIn(ana);
      await tester.pumpAndSettle();
      await openTab(tester, 'Cart');
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('a sign-out that fails is reported', (tester) async {
      final backend = await openApp(tester, signedInAs: ana);
      backend.errors['signOut'] = offline;
      await openTab(tester, 'Account');
      await tap(tester, outlinedButton('Sign out'));
      expect(find.text('Could not reach Supabase.'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });
  });

  group('on a phone', () {
    for (final size in [phone, const Size(320, 640)]) {
      testWidgets('every customer page fits ${size.width.round()} px', (
        tester,
      ) async {
        final backend = await openApp(tester, signedInAs: ana, size: size);
        expect(find.byType(NavigationBar), findsOneWidget);
        backend.change(
          'Steel Tumbler',
          newName: 'A Very Long Product Name Here',
        );
        await tap(tester, find.byTooltip('Refresh'));
        await tap(tester, find.text('A Very Long Product Name Here'));
        expect(find.byType(ProductDetailsPage), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await addToCart(tester, 'A Very Long Product Name Here');

        await openTab(tester, 'Cart');
        await tap(tester, filledButton('Checkout'));
        expect(find.byType(OrderConfirmationPage), findsOneWidget);
        await tap(tester, filledButton('View my orders'));
        expect(find.byType(OrderCard), findsOneWidget);
        await openTab(tester, 'Account');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('turning the device keeps the cart and the page', (
      tester,
    ) async {
      await openApp(tester, signedInAs: ana, size: phone);
      await tester.scrollUntilVisible(
        find.byTooltip('Next page'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tap(tester, find.byTooltip('Next page'));
      tester.view.physicalSize = const Size(1100, 800);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.textContaining('Page 2 of 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
