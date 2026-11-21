import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/screens/shop_screen.dart';
import 'package:my_first_flutter_ui/widgets/product_card.dart';

import 'support/fake_auth_repository.dart';
import 'support/fake_product_repository.dart';

void main() {
  Future<FakeAuthRepository> openApp(
    WidgetTester tester, {
    FakeAuthRepository? auth,
  }) async {
    tester.view.physicalSize = const Size(1400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = auth ?? FakeAuthRepository();
    await tester.pumpWidget(
      ShopApp(auth: repository, products: FakeProductRepository()),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  /// FilledButton.icon builds a private subclass, so match by type test.
  Finder gitHubButton() => find.ancestor(
    of: find.text('Continue with GitHub'),
    matching: find.byWidgetPredicate((widget) => widget is FilledButton),
  );

  testWidgets('signed out, the app offers email and GitHub sign-in', (
    tester,
  ) async {
    await openApp(tester);

    expect(find.text('Sign in to browse and manage products'), findsOneWidget);
    expect(field('Email'), findsOneWidget);
    expect(field('Password'), findsOneWidget);
    expect(find.text('Continue with GitHub'), findsOneWidget);
    expect(find.byType(ShopScreen), findsNothing);
  });

  testWidgets('the email form checks its fields, then opens the shop', (
    tester,
  ) async {
    await openApp(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(field('Email'), 'shopper@example.com');
    await tester.enterText(field('Password'), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong email or password.'), findsOneWidget);

    await tester.enterText(field('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopScreen), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(6));
  });

  testWidgets('GitHub signs in when the browser comes back, then signs out', (
    tester,
  ) async {
    final auth = await openApp(tester);

    await tester.tap(find.text('Continue with GitHub'));
    await tester.pumpAndSettle();
    expect(auth.gitHubRequests, 1);
    expect(find.text('Finish signing in on the GitHub page.'), findsOneWidget);

    auth.finishGitHubSignIn();
    await tester.pumpAndSettle();
    expect(find.byType(ShopScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Octo Cat'), findsOneWidget);
    expect(find.text('octocat@example.com'), findsOneWidget);
    expect(find.text('Signed in with GitHub'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.byType(ShopScreen), findsNothing);
    expect(find.text('Continue with GitHub'), findsOneWidget);
  });

  testWidgets('a cancelled GitHub sign-in shows the reason', (tester) async {
    final auth = await openApp(tester);

    await tester.tap(find.text('Continue with GitHub'));
    await tester.pumpAndSettle();
    auth.failGitHubSignIn('The user has denied your application access.');
    await tester.pumpAndSettle();

    expect(
      find.text('The user has denied your application access.'),
      findsOneWidget,
    );
    expect(find.byType(ShopScreen), findsNothing);
  });

  testWidgets('creating an account asks to confirm the email', (tester) async {
    await openApp(tester, auth: FakeAuthRepository(confirmEmail: true));

    await tester.tap(find.text('No account yet? Create one'));
    await tester.pump();
    await tester.enterText(field('Email'), 'new@example.com');
    await tester.enterText(field('Password'), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();
    expect(find.text('Use at least 6 characters'), findsOneWidget);

    await tester.enterText(field('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('confirmation link'), findsOneWidget);
    expect(find.byType(ShopScreen), findsNothing);
  });

  testWidgets('a saved session skips the sign-in screen', (tester) async {
    await openApp(tester, auth: FakeAuthRepository(signedIn: gitHubUser));

    expect(find.byType(ShopScreen), findsOneWidget);
    expect(find.text('Continue with GitHub'), findsNothing);
  });

  testWidgets('on desktop the GitHub button is off and says why', (
    tester,
  ) async {
    await openApp(tester, auth: FakeAuthRepository(gitHubAvailable: false));

    expect(tester.widget<FilledButton>(gitHubButton()).onPressed, isNull);
    expect(
      find.textContaining('works in the web and mobile versions'),
      findsOneWidget,
    );
  });
}
