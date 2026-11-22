import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/models/profile.dart';
import 'package:my_first_flutter_ui/widgets/product_card.dart';

import 'fake_backend.dart';

const desktop = Size(1400, 1100);
const phone = Size(390, 844);

/// Starts the whole app on [backend].
Future<FakeBackend> openApp(
  WidgetTester tester, {
  Profile? signedInAs,
  FakeBackend? backend,
  Size size = desktop,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake = backend ?? FakeBackend(signedInAs: signedInAs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: fake.overrides,
      retry: noRetry,
      child: const ShopApp(),
    ),
  );
  await tester.pumpAndSettle();
  return fake;
}

/// Opens a tab of the bottom bar or side rail.
Future<void> openTab(WidgetTester tester, String label) async {
  final bar = find.byWidgetPredicate(
    (widget) => widget is NavigationBar || widget is NavigationRail,
  );
  await tester.tap(find.descendant(of: bar, matching: find.text(label)).first);
  await tester.pumpAndSettle();
}

Finder tabs(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (widget) => widget is NavigationBar || widget is NavigationRail,
  ),
  matching: find.text(label),
);

Finder card(String product) =>
    find.ancestor(of: find.text(product), matching: find.byType(ProductCard));

/// Something inside one product's card.
Finder inCard(String product, Finder finder) =>
    find.descendant(of: card(product), matching: finder);

Finder field(String label) => find.widgetWithText(TextFormField, label);

/// Any kind of filled button, including the ones with icons.
Finder filledButton(String text) => find.ancestor(
  of: find.text(text),
  matching: find.byWidgetPredicate((widget) => widget is FilledButton),
);

Finder outlinedButton(String text) => find.ancestor(
  of: find.text(text),
  matching: find.byWidgetPredicate((widget) => widget is OutlinedButton),
);

bool isEnabled(WidgetTester tester, Finder button) =>
    tester.widget<ButtonStyleButton>(button).onPressed != null;

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

List<String> visibleProducts(WidgetTester tester) => [
  for (final card in tester.widgetList<ProductCard>(find.byType(ProductCard)))
    card.product.name,
];
