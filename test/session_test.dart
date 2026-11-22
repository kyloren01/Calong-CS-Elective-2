import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/profile.dart';
import 'package:my_first_flutter_ui/models/session_user.dart';
import 'package:my_first_flutter_ui/providers/auth_controller.dart';
import 'package:my_first_flutter_ui/providers/session_providers.dart';

import 'support/containers.dart';
import 'support/fake_backend.dart';

void main() {
  group('session and role', () {
    test('signed out: no user, no profile, not an admin', () async {
      final container = await openContainer(FakeBackend());
      expect(container.read(userIdProvider), isNull);
      expect(await container.read(profileProvider.future), isNull);
      expect(container.read(isAdminProvider), isFalse);
    });

    test('a saved session loads the profile and its role', () async {
      final customer = await openContainer(FakeBackend(signedInAs: ana));
      expect(
        (await customer.read(profileProvider.future))!.fullName,
        'Ana Cruz',
      );
      expect(customer.read(isAdminProvider), isFalse);

      final admin = await openContainer(FakeBackend(signedInAs: boss));
      await admin.read(profileProvider.future);
      expect(admin.read(isAdminProvider), isTrue);
    });

    test("an admin's role never carries over to the next person", () async {
      final backend = FakeBackend(signedInAs: boss);
      final container = await openContainer(backend);
      container.listen(isAdminProvider, (_, _) {});
      await container.read(profileProvider.future);
      expect(container.read(isAdminProvider), isTrue);

      // Ana's profile takes a while to load.
      final gate = backend.gates['fetchProfile'] = Completer();
      backend.signIn(ana);
      await settle();
      expect(container.read(userIdProvider), 'ana');
      expect(container.read(isAdminProvider), isFalse);

      gate.complete();
      await settle();
      expect(container.read(isAdminProvider), isFalse);
    });

    test('a profile with an unknown role gets the fewest rights', () {
      final profile = Profile.fromJson({
        'id': 'x',
        'email': null,
        'firstname': null,
        'lastname': null,
        'roles': {'role': 'superuser'},
      });
      expect(profile.role, UserRole.customer);
      expect(profile.displayName, 'Customer');
    });

    test('a session error does not sign anyone out', () async {
      final backend = FakeBackend(signedInAs: ana);
      final container = await openContainer(backend);
      backend.failSession('Token refresh failed.');
      await settle();
      expect(container.read(userIdProvider), 'ana');

      // And the stream still works afterwards.
      backend.signOut();
      await settle();
      expect(container.read(userIdProvider), isNull);
    });

    test('saving a name reloads the profile', () async {
      final backend = FakeBackend(signedInAs: ana);
      final container = await openContainer(backend);
      container.listen(profileProvider, (_, _) {});
      await container.read(profileProvider.future);

      final error = await container
          .read(profileSaveProvider.notifier)
          .saveName(firstName: 'Anna', lastName: 'Cruz');
      expect(error, isNull);
      expect(
        (await container.read(profileProvider.future))!.fullName,
        'Anna Cruz',
      );
    });
  });

  group('sign-in form', () {
    test('a correct password signs in', () async {
      final backend = FakeBackend();
      final container = await openContainer(backend);
      container.listen(authControllerProvider, (_, _) {});
      final controller = container.read(authControllerProvider.notifier);

      final pending = controller.signIn(
        email: 'ana@example.com',
        password: password,
      );
      expect(container.read(authControllerProvider).busy, AuthAction.signIn);
      await pending;
      await settle();
      expect(container.read(userIdProvider), 'ana');
      expect(container.read(authControllerProvider).isBusy, isFalse);
    });

    test('a wrong password shows a message and stays signed out', () async {
      final container = await openContainer(FakeBackend());
      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn(email: 'ana@example.com', password: 'nope');
      expect(
        container.read(authControllerProvider).error,
        'Wrong email or password.',
      );
      expect(container.read(userIdProvider), isNull);

      controller.clearMessages();
      expect(container.read(authControllerProvider).error, isNull);
    });

    test('signing up makes a customer', () async {
      final backend = FakeBackend();
      final container = await openContainer(backend);
      await container
          .read(authControllerProvider.notifier)
          .signUp(
            firstName: 'New',
            lastName: 'Person',
            email: 'new@example.com',
            password: password,
          );
      await settle();
      final profile = await container.read(profileProvider.future);
      expect(profile!.role, UserRole.customer);
      expect(profile.fullName, 'New Person');
    });

    test('signing up may need the email confirmed first', () async {
      final backend = FakeBackend()..confirmEmail = true;
      final container = await openContainer(backend);
      container.listen(authControllerProvider, (_, _) {});
      await container
          .read(authControllerProvider.notifier)
          .signUp(
            firstName: 'New',
            lastName: 'Person',
            email: 'new@example.com',
            password: password,
          );
      await settle();
      expect(container.read(userIdProvider), isNull);
      expect(
        container.read(authControllerProvider).info,
        contains('confirmation link'),
      );
    });

    test('Google signs in when the browser comes back', () async {
      final backend = FakeBackend();
      final container = await openContainer(backend);
      container.listen(authControllerProvider, (_, _) {});
      await container.read(authControllerProvider.notifier).signInWithGoogle();
      expect(backend.calls, contains('signInWithGoogle'));
      expect(container.read(authControllerProvider).info, contains('Google'));

      backend.signIn(ben);
      await settle();
      expect(container.read(userIdProvider), 'ben');
      expect(container.read(authControllerProvider).info, isNull);
    });

    test("cancelling on Google's page shows the reason", () async {
      final backend = FakeBackend();
      final container = await openContainer(backend);
      container.listen(authControllerProvider, (_, _) {});
      container.read(authControllerProvider);
      backend.failSession('The user denied access.');
      await settle();
      expect(
        container.read(authControllerProvider).error,
        'The user denied access.',
      );
      expect(container.read(userIdProvider), isNull);
    });

    test('a second button press is ignored while one is running', () async {
      final backend = FakeBackend();
      final container = await openContainer(backend);
      final controller = container.read(authControllerProvider.notifier);
      final first = controller.signIn(
        email: 'ana@example.com',
        password: password,
      );
      await controller.signInWithGoogle();
      await first;
      expect(backend.calls, isNot(contains('signInWithGoogle')));
    });

    test('a failed sign-out is reported', () async {
      final backend = FakeBackend(signedInAs: ana);
      backend.errors['signOut'] = offline;
      final container = await openContainer(backend);
      await container.read(authControllerProvider.notifier).signOut();
      expect(
        container.read(authControllerProvider).error,
        'Could not reach Supabase.',
      );
      expect(container.read(userIdProvider), 'ana');
    });
  });

  test('session users compare by value', () {
    expect(
      const SessionUser(id: 'a', email: 'b'),
      const SessionUser(id: 'a', email: 'b'),
    );
  });
}
