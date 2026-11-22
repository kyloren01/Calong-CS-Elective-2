import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/pages/admin/admin_shell.dart';
import 'package:my_first_flutter_ui/pages/auth/login_page.dart';
import 'package:my_first_flutter_ui/pages/auth/sign_up_page.dart';
import 'package:my_first_flutter_ui/pages/customer/customer_shell.dart';
import 'package:my_first_flutter_ui/pages/customer/product_details_page.dart';
import 'package:my_first_flutter_ui/pages/setup_page.dart';

import 'support/app_tester.dart';
import 'support/fake_backend.dart';

void main() {
  testWidgets('signed out, only the login page shows and nothing is loaded', (
    tester,
  ) async {
    final backend = await openApp(tester);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(field('Email'), findsOneWidget);
    expect(field('Password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(backend.calls, isEmpty);
  });

  testWidgets('logging in: checks, wrong password, then the shop', (
    tester,
  ) async {
    await openApp(tester);
    await tap(tester, filledButton('Log in'));
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(field('Email'), 'ana@example.com');
    await tester.enterText(field('Password'), 'wrong');
    await tap(tester, filledButton('Log in'));
    expect(find.text('Wrong email or password.'), findsOneWidget);

    await tester.enterText(field('Password'), password);
    await tap(tester, filledButton('Log in'));
    expect(find.byType(CustomerShell), findsOneWidget);
  });

  testWidgets('signing up: checks, then a customer account', (tester) async {
    await openApp(tester);
    await tap(tester, find.text('No account yet? Sign up'));
    expect(find.byType(SignUpPage), findsOneWidget);

    await tap(tester, filledButton('Create account'));
    expect(find.text('Enter your first name'), findsOneWidget);
    expect(find.text('Enter your last name'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);

    await tester.enterText(field('First name'), 'Nina');
    await tester.enterText(field('Last name'), 'Santos');
    await tester.enterText(field('Email'), 'nina@example.com');
    await tester.enterText(field('Password'), password);
    await tester.enterText(field('Repeat password'), 'different');
    await tap(tester, filledButton('Create account'));
    expect(find.text('The passwords are different'), findsOneWidget);

    await tester.enterText(field('Repeat password'), password);
    await tap(tester, filledButton('Create account'));
    // The sign-up page closes by itself, and the role is customer.
    expect(find.byType(SignUpPage), findsNothing);
    expect(find.byType(CustomerShell), findsOneWidget);
    await openTab(tester, 'Account');
    expect(find.text('Nina Santos'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
  });

  testWidgets('signing up with an email that must be confirmed', (
    tester,
  ) async {
    await openApp(tester, backend: FakeBackend()..confirmEmail = true);
    await tap(tester, find.text('No account yet? Sign up'));
    await tester.enterText(field('First name'), 'Nina');
    await tester.enterText(field('Last name'), 'Santos');
    await tester.enterText(field('Email'), 'nina@example.com');
    await tester.enterText(field('Password'), password);
    await tester.enterText(field('Repeat password'), password);
    await tap(tester, filledButton('Create account'));
    expect(find.textContaining('confirmation link'), findsOneWidget);

    await tap(tester, find.text('Already have an account? Log in'));
    expect(find.byType(SignUpPage), findsNothing);
    expect(find.textContaining('confirmation link'), findsNothing);
  });

  testWidgets('Google signs in when the browser comes back', (tester) async {
    final backend = await openApp(tester);
    await tap(tester, outlinedButton('Continue with Google'));
    expect(backend.calls, ['signInWithGoogle']);
    expect(find.textContaining('Finish signing in'), findsOneWidget);

    backend.signIn(ben);
    await tester.pumpAndSettle();
    expect(find.byType(CustomerShell), findsOneWidget);
  });

  testWidgets("cancelling on Google's page shows the reason", (tester) async {
    final backend = await openApp(tester);
    backend.failSession('The user denied access.');
    await tester.pumpAndSettle();
    expect(find.text('The user denied access.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('on desktop the Google button is off and says why', (
    tester,
  ) async {
    await openApp(tester, backend: FakeBackend()..googleAvailable = false);
    expect(isEnabled(tester, outlinedButton('Continue with Google')), isFalse);
    expect(find.textContaining('web and mobile versions'), findsOneWidget);
  });

  testWidgets('the role decides which app opens', (tester) async {
    await openApp(tester, signedInAs: boss);
    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(CustomerShell), findsNothing);
  });

  testWidgets('changing accounts switches between the two apps', (
    tester,
  ) async {
    final backend = await openApp(tester, signedInAs: boss);
    backend.signIn(ana);
    await tester.pumpAndSettle();
    expect(find.byType(CustomerShell), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);

    backend.signIn(boss);
    await tester.pumpAndSettle();
    expect(find.byType(AdminShell), findsOneWidget);
  });

  testWidgets('when the session ends, open pages close too', (tester) async {
    final backend = await openApp(tester, signedInAs: ana);
    await tap(tester, find.text('Steel Tumbler'));
    expect(find.byType(ProductDetailsPage), findsOneWidget);

    backend.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsPage), findsNothing);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('a profile that cannot load can be tried again', (tester) async {
    final backend = FakeBackend(signedInAs: ana);
    backend.errors['fetchProfile'] = offline;
    await openApp(tester, backend: backend);
    expect(find.text('No connection'), findsOneWidget);
    expect(find.byType(CustomerShell), findsNothing);

    backend.errors.clear();
    await tap(tester, filledButton('Try again'));
    expect(find.byType(CustomerShell), findsOneWidget);
  });

  testWidgets("a failed profile never shows the previous person's app", (
    tester,
  ) async {
    final backend = await openApp(tester, signedInAs: boss);
    backend.errors['fetchProfile'] = offline;
    backend.signIn(ana);
    await tester.pumpAndSettle();
    expect(find.byType(AdminShell), findsNothing);
    expect(find.text('No connection'), findsOneWidget);
  });

  testWidgets('an account without a profile is explained', (tester) async {
    final backend = FakeBackend(signedInAs: ana)..profiles.remove('ana');
    await openApp(tester, backend: backend);
    expect(find.text('No profile found'), findsOneWidget);

    await tap(tester, find.text('Sign out'));
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('login and sign-up fit a small phone', (tester) async {
    await openApp(tester, size: const Size(320, 640));
    await tap(tester, find.text('No account yet? Sign up'));
    expect(find.byType(SignUpPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('without Supabase keys, the steps are explained', (tester) async {
    await tester.pumpWidget(const SetupApp(problem: 'Something failed'));
    expect(find.text('Connect to Supabase'), findsOneWidget);
    expect(find.textContaining('supabase.json'), findsWidgets);
    expect(find.text('Something failed'), findsOneWidget);
  });

  testWidgets('passwords can be shown', (tester) async {
    await openApp(tester);
    await tester.enterText(field('Password'), password);
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tap(tester, find.byTooltip('Show password'));
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: field('Password'),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText,
      isFalse,
    );
  });
}
