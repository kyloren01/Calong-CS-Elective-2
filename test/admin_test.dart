import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/app_exception.dart';
import 'package:my_first_flutter_ui/models/order.dart';
import 'package:my_first_flutter_ui/models/profile.dart';
import 'package:my_first_flutter_ui/pages/admin/product_form_page.dart';
import 'package:my_first_flutter_ui/widgets/order_card.dart';

import 'support/app_tester.dart';
import 'support/fake_backend.dart';

void main() {
  SavedOrder order(int id, Profile customer, OrderStatus status) => SavedOrder(
    userId: customer.id,
    order: Order(
      id: id,
      status: status,
      total: 128,
      createdAt: DateTime(2026, 11, 20 + id, 9, 5),
      items: const [
        OrderItem(productName: 'Chef Knife', unitPrice: 64, quantity: 2),
      ],
    ),
  );

  group('what an admin sees', () {
    testWidgets('Add, Edit, and Delete, but no cart', (tester) async {
      await openApp(tester, signedInAs: boss);
      expect(
        find.widgetWithText(FloatingActionButton, 'Add product'),
        findsOneWidget,
      );
      expect(find.text('Edit'), findsNWidgets(6));
      expect(find.byTooltip('Delete Bento Box'), findsOneWidget);
      expect(inCard('Cloud Pillow', find.text('40 in stock')), findsOneWidget);

      expect(find.text('Add to cart'), findsNothing);
      expect(tabs('Cart'), findsNothing);
      for (final tab in ['Products', 'Categories', 'Orders', 'Account']) {
        expect(tabs(tab), findsWidgets, reason: tab);
      }
    });

    testWidgets('admins have no "Edit name"', (tester) async {
      await openApp(tester, signedInAs: boss);
      await openTab(tester, 'Account');
      expect(find.text('Bea Boss'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Edit name'), findsNothing);
    });
  });

  group('products', () {
    Future<void> openAddForm(WidgetTester tester) =>
        tap(tester, find.byType(FloatingActionButton));

    Future<void> chooseCategory(WidgetTester tester, String name) async {
      await tap(tester, find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    testWidgets('the Add button opens the form, which checks every field', (
      tester,
    ) async {
      final backend = await openApp(tester, signedInAs: boss);
      await openAddForm(tester);
      expect(find.byType(ProductFormPage), findsOneWidget);

      await tap(tester, filledButton('Add product'));
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('Enter a price'), findsOneWidget);
      expect(find.text('Enter the stock'), findsOneWidget);
      expect(find.text('Choose a category'), findsOneWidget);

      await tester.enterText(field('Price'), '-5');
      await tester.enterText(field('Stock quantity'), '1.5');
      await tap(tester, filledButton('Add product'));
      expect(find.text('The price must be 0 or more'), findsOneWidget);
      expect(find.text('Enter a whole number, such as 10'), findsOneWidget);

      await tester.enterText(field('Price'), 'abc');
      await tester.enterText(field('Stock quantity'), '-1');
      await tap(tester, filledButton('Add product'));
      expect(find.text('Enter a number, such as 49.99'), findsOneWidget);
      expect(find.text('The stock must be 0 or more'), findsOneWidget);
      expect(backend.products, hasLength(24));
    });

    testWidgets('adding a product with a picture', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      backend.nextPick = tinyPng;
      await openAddForm(tester);
      expect(find.text('No picture yet'), findsOneWidget);
      await tap(tester, outlinedButton('Choose picture'));
      expect(find.text('No picture yet'), findsNothing);

      await tester.enterText(field('Name'), 'Desk Mat');
      await tester.enterText(field('Description'), 'Soft felt.');
      await tester.enterText(field('Price'), '12.5');
      await tester.enterText(field('Stock quantity'), '3');
      await chooseCategory(tester, 'Home');
      await tap(tester, filledButton('Add product'));

      expect(find.byType(ProductFormPage), findsNothing);
      expect(find.text('Product added.'), findsOneWidget);
      expect(visibleProducts(tester).first, 'Desk Mat');
      final saved = backend.product('Desk Mat');
      expect(saved.description, 'Soft felt.');
      expect(saved.price, 12.5);
      expect(saved.stock, 3);
      expect(saved.categoryName, 'Home');
      expect(backend.images, {saved.imagePath});
    });

    testWidgets('a picture can be taken back, or refused', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      backend.nextPick = tinyPng;
      await openAddForm(tester);
      await tap(tester, outlinedButton('Choose picture'));
      await tap(tester, find.text('Remove picture'));
      expect(find.text('No picture yet'), findsOneWidget);

      backend.errors['pickImage'] = const AppException(
        'Use a JPG, PNG, WebP, or GIF picture.',
      );
      await tap(tester, outlinedButton('Choose picture'));
      expect(
        find.text('Use a JPG, PNG, WebP, or GIF picture.'),
        findsOneWidget,
      );
    });

    testWidgets('editing starts with the current values', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      await tap(tester, inCard('Steel Tumbler', find.text('Edit')));
      expect(find.text('Edit product'), findsOneWidget);
      String value(String label) =>
          tester.widget<TextFormField>(field(label)).controller!.text;
      expect(value('Name'), 'Steel Tumbler');
      expect(value('Description'), 'About the Steel Tumbler.');
      expect(value('Price'), '22.00');
      expect(value('Stock quantity'), '45');
      expect(find.text('Kitchen'), findsOneWidget);

      await tester.enterText(field('Name'), 'Big Tumbler');
      await tester.enterText(field('Price'), '300');
      await tester.enterText(field('Stock quantity'), '0');
      await chooseCategory(tester, 'Home');
      await tap(tester, filledButton('Save changes'));
      expect(find.text('Changes saved.'), findsOneWidget);
      final saved = backend.product('Big Tumbler');
      expect(saved.price, 300);
      expect(saved.stock, 0);
      expect(saved.categoryName, 'Home');
      expect(backend.products, hasLength(24));
    });

    testWidgets('deleting asks first, naming the product', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      await tap(tester, find.byTooltip('Delete Steel Tumbler'));
      expect(find.text('Delete Steel Tumbler?'), findsOneWidget);
      await tap(tester, find.text('Cancel'));
      expect(backend.products, hasLength(24));

      await tap(tester, find.byTooltip('Delete Steel Tumbler'));
      await tap(tester, filledButton('Delete'));
      expect(find.text('Steel Tumbler deleted.'), findsOneWidget);
      expect(visibleProducts(tester), isNot(contains('Steel Tumbler')));
      expect(backend.products, hasLength(23));
    });

    testWidgets('a failed save keeps the form and says why', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      backend.errors['updateProduct'] = offline;
      await tap(tester, inCard('Steel Tumbler', find.text('Edit')));
      await tester.enterText(field('Name'), 'Big Tumbler');
      await tap(tester, filledButton('Save changes'));
      expect(find.byType(ProductFormPage), findsOneWidget);
      expect(find.text('Could not reach Supabase.'), findsOneWidget);
      expect(find.text('Big Tumbler'), findsOneWidget);

      backend.errors.clear();
      await tap(tester, filledButton('Save changes'));
      expect(find.byType(ProductFormPage), findsNothing);
    });

    testWidgets('an admin who lost the role is told so', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      // Someone changes the role while the app is open.
      backend.setRole(boss, UserRole.customer);

      await tap(tester, find.byTooltip('Delete Steel Tumbler'));
      await tap(tester, filledButton('Delete'));
      expect(find.text(permissionDenied.message), findsOneWidget);
      expect(backend.products, hasLength(24));

      await tap(tester, inCard('Steel Tumbler', find.text('Edit')));
      await tap(tester, filledButton('Save changes'));
      expect(find.byType(ProductFormPage), findsOneWidget);
      expect(find.text(permissionDenied.message), findsWidgets);
    });

    testWidgets('the form explains when there are no categories', (
      tester,
    ) async {
      final backend = FakeBackend(signedInAs: boss)
        ..products.clear()
        ..categories.clear();
      await openApp(tester, backend: backend);
      expect(find.text('No products yet'), findsOneWidget);
      await openAddForm(tester);
      expect(
        find.textContaining('There are no categories yet'),
        findsOneWidget,
      );
    });

    testWidgets('categories that fail to load in the form can be retried', (
      tester,
    ) async {
      final backend = FakeBackend(signedInAs: boss);
      backend.errors['fetchCategories'] = offline;
      await openApp(tester, backend: backend);
      await openAddForm(tester);
      expect(find.text('Could not reach Supabase.'), findsOneWidget);
      backend.errors.clear();
      await tap(tester, find.text('Try again'));
      expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    });
  });

  group('categories', () {
    testWidgets('add, rename, and delete', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      await openTab(tester, 'Categories');
      await tap(
        tester,
        find.widgetWithText(FloatingActionButton, 'Add category'),
      );
      await tap(tester, filledButton('Save'));
      expect(find.text('Enter a name'), findsOneWidget);

      await tester.enterText(field('Category name'), 'Audio');
      await tap(tester, filledButton('Save'));
      expect(find.text('That name is already in use.'), findsOneWidget);

      await tester.enterText(field('Category name'), 'Art');
      await tap(tester, filledButton('Save'));
      expect(find.text('Category added.'), findsOneWidget);
      expect(find.text('Art'), findsOneWidget);

      await tap(tester, find.byTooltip('Rename Art'));
      await tester.enterText(field('Category name'), 'Arts');
      await tap(tester, filledButton('Save'));
      expect(find.text('Category renamed.'), findsOneWidget);

      await tap(tester, find.byTooltip('Delete Arts'));
      expect(find.text('Delete Arts?'), findsOneWidget);
      await tap(tester, filledButton('Delete'));
      expect(find.text('Arts deleted.'), findsOneWidget);
      expect(backend.categories, hasLength(7));
    });

    testWidgets('one with products is kept, with the reason', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      await openTab(tester, 'Categories');
      await tap(tester, find.byTooltip('Delete Audio'));
      await tap(tester, filledButton('Delete'));
      expect(find.textContaining('still has products'), findsOneWidget);
      expect(backend.categories, hasLength(7));
    });
  });

  group('orders', () {
    testWidgets('every order with its customer, filtered by status', (
      tester,
    ) async {
      final backend = FakeBackend(signedInAs: boss)
        ..orders.addAll([
          order(1, ana, OrderStatus.done),
          order(2, ben, OrderStatus.processing),
        ]);
      await openApp(tester, backend: backend);
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
      expect(find.text('Ana Cruz · ana@example.com'), findsOneWidget);
      expect(find.text('Ben Reyes · ben@example.com'), findsOneWidget);

      await tap(tester, find.widgetWithText(ChoiceChip, 'Processing (1)'));
      expect(find.byType(OrderCard), findsOneWidget);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Cancelled (0)'));
      expect(find.text('No cancelled orders'), findsOneWidget);
    });

    testWidgets('the status can be changed', (tester) async {
      final backend = FakeBackend(signedInAs: boss)
        ..orders.add(order(1, ana, OrderStatus.done));
      await openApp(tester, backend: backend);
      await openTab(tester, 'Orders');
      await tap(tester, find.byTooltip('Change the status of order #00001'));
      await tap(
        tester,
        find.widgetWithText(PopupMenuItem<OrderStatus>, 'Cancelled'),
      );
      expect(find.text('Order #00001 is now cancelled.'), findsOneWidget);
      expect(backend.orders.single.order.status, OrderStatus.cancelled);
      expect(find.byType(OrderStatusChip), findsOneWidget);
    });

    testWidgets('a status that cannot be saved is reported', (tester) async {
      final backend = FakeBackend(signedInAs: boss)
        ..orders.add(order(1, ana, OrderStatus.done));
      backend.errors['updateStatus'] = offline;
      await openApp(tester, backend: backend);
      await openTab(tester, 'Orders');
      await tap(tester, find.byTooltip('Change the status of order #00001'));
      await tap(
        tester,
        find.widgetWithText(PopupMenuItem<OrderStatus>, 'Pending'),
      );
      expect(find.text('Could not reach Supabase.'), findsOneWidget);
      expect(backend.orders.single.order.status, OrderStatus.done);
    });

    testWidgets('empty, and permission denied', (tester) async {
      final backend = await openApp(tester, signedInAs: boss);
      await openTab(tester, 'Orders');
      expect(find.text('No orders yet'), findsOneWidget);

      backend.setRole(boss, UserRole.customer);
      await tap(tester, find.byTooltip('Refresh'));
      expect(find.text('Permission denied'), findsOneWidget);
    });
  });

  group('on a phone', () {
    for (final size in [phone, const Size(320, 640)]) {
      testWidgets('every admin page fits ${size.width.round()} px', (
        tester,
      ) async {
        final backend = FakeBackend(signedInAs: boss)
          ..orders.add(order(1, ana, OrderStatus.processing));
        await openApp(tester, backend: backend, size: size);
        await tap(tester, find.byType(FloatingActionButton).first);
        expect(find.byType(ProductFormPage), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await openTab(tester, 'Categories');
        await openTab(tester, 'Orders');
        expect(find.byType(OrderCard), findsOneWidget);
        await openTab(tester, 'Account');
        expect(tester.takeException(), isNull);
      });
    }
  });
}
