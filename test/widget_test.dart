import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/data/product_repository.dart';
import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/screens/setup_required_screen.dart';
import 'package:my_first_flutter_ui/screens/shop_screen.dart';
import 'package:my_first_flutter_ui/state/shop_cubit.dart';
import 'package:my_first_flutter_ui/widgets/product_card.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_product_repository.dart';

void main() {
  Future<FakeProductRepository> openShop(
    WidgetTester tester, {
    Object? error,
  }) async {
    // A desktop-sized window, so all 6 cards are on screen in one row.
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeProductRepository()..error = error;
    await tester.pumpWidget(
      ShopApp(
        auth: FakeAuthRepository(signedIn: emailUser),
        products: repository,
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  ShopCubit cubitOf(WidgetTester tester) =>
      BlocProvider.of<ShopCubit>(tester.element(find.byType(ShopScreen)));

  List<String> visibleNames(WidgetTester tester) => tester
      .widgetList<ProductCard>(find.byType(ProductCard))
      .map((card) => card.product.name)
      .toList();

  testWidgets('shows 6 products per page and pages through them', (
    tester,
  ) async {
    final repository = await openShop(tester);
    expect(visibleNames(tester), [
      'Bento Box',
      'Steel Tumbler',
      'Slide Sandals',
      'Laptop Sleeve',
      'Wireless Charger',
      'Cloud Pillow',
    ]);
    expect(
      find.text('Showing 1–6 of 24 products · Page 1 of 4'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(visibleNames(tester).first, 'Transit Sling');
    expect(
      find.text('Showing 7–12 of 24 products · Page 2 of 4'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(TextButton, '4'));
    await tester.pumpAndSettle();
    expect(visibleNames(tester).last, 'Trail Watch');
    final next = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
    );
    expect(next.onPressed, isNull);
    expect(repository.pageRequests.map((r) => r.page), [1, 2, 4]);
  });

  testWidgets('the price slider and category chips re-query the products', (
    tester,
  ) async {
    final repository = await openShop(tester);

    // Drag the slider's left thumb to the right.
    final slider = tester.getRect(find.byType(RangeSlider));
    await tester.dragFrom(
      Offset(slider.left + 24, slider.center.dy),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();

    final selected = cubitOf(tester).state.selectedPrice!;
    expect(selected.min, greaterThan(18));
    expect(selected.max, 249);
    expect(repository.pageRequests.last, (
      page: 1,
      price: selected,
      category: null,
    ));
    expect(find.text('\$${selected.min.round()} – \$249'), findsOneWidget);
    for (final card in tester.widgetList<ProductCard>(find.byType(ProductCard))) {
      expect(card.product.price, greaterThanOrEqualTo(selected.min));
    }

    await tester.tap(find.widgetWithText(ChoiceChip, 'Audio'));
    await tester.pumpAndSettle();
    expect(repository.pageRequests.last.category, 'Audio');
    expect(repository.pageRequests.last.price, selected);
    for (final card in tester.widgetList<ProductCard>(find.byType(ProductCard))) {
      expect(card.product.category, 'Audio');
    }

    await tester.tap(find.text('Clear filters').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Showing 1–6 of 24 products · Page 1 of 4'),
      findsOneWidget,
    );
  });

  testWidgets('edits, deletes, and adds products through the dialogs', (
    tester,
  ) async {
    final repository = await openShop(tester);

    // Edit: Bento Box becomes the priciest product, so it leaves page 1.
    await tester.tap(find.byTooltip('Edit Bento Box'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '300');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Changes saved.'), findsOneWidget);
    expect(repository.byName('Bento Box').price, 300);
    expect(visibleNames(tester), isNot(contains('Bento Box')));
    expect(cubitOf(tester).state.priceBounds, const PriceRange(22, 300));

    // Delete, after confirming.
    await tester.tap(find.byTooltip('Delete Steel Tumbler'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Steel Tumbler deleted.'), findsOneWidget);
    expect(visibleNames(tester), isNot(contains('Steel Tumbler')));
    expect(repository.products, hasLength(23));

    // Add, picking an existing category.
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Desk Mat');
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '12.5');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ChoiceChip, 'Home'),
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('Product added.'), findsOneWidget);
    expect(repository.byName('Desk Mat').category, 'Home');
    expect(visibleNames(tester).first, 'Desk Mat');
  });

  testWidgets('the form checks the name and price before saving', (
    tester,
  ) async {
    final repository = await openShop(tester);

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a price, such as 49.99'), findsOneWidget);
    expect(find.text('Enter or pick a category'), findsOneWidget);
    expect(repository.products, hasLength(24));
  });

  testWidgets('shows the Supabase error and tries again', (tester) async {
    final repository = await openShop(
      tester,
      error: const ProductRepositoryException('Could not reach Supabase.'),
    );
    expect(find.text('Could not reach Supabase.'), findsOneWidget);

    repository.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductCard), findsNWidgets(6));
  });

  testWidgets('explains how to connect when Supabase is not set up', (
    tester,
  ) async {
    await tester.pumpWidget(const SetupRequiredApp());
    expect(find.text('Connect to Supabase'), findsOneWidget);
    expect(find.textContaining('supabase.json'), findsWidgets);
  });
}
