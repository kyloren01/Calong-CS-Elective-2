import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/state/auth_cubit.dart';
import 'package:my_first_flutter_ui/state/auth_state.dart';

import 'support/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late AuthCubit cubit;

  setUp(() {
    auth = FakeAuthRepository();
    cubit = AuthCubit(repository: auth)..start();
  });
  tearDown(() => cubit.close());

  /// Lets stream events from the fake reach the Cubit.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts signed out when there is no saved session', () {
    expect(cubit.state.status, AuthStatus.signedOut);
    expect(cubit.state.user, isNull);
  });

  test('a saved session signs in right away', () {
    final restored = AuthCubit(
      repository: FakeAuthRepository(signedIn: gitHubUser),
    )..start();
    addTearDown(restored.close);

    expect(restored.state.status, AuthStatus.signedIn);
    expect(restored.state.user, gitHubUser);
  });

  test('email sign-in shows a spinner, then signs in', () async {
    final pending = cubit.signInWithEmail('shopper@example.com', 'secret123');
    expect(cubit.state.busy, AuthAction.emailSignIn);

    await pending;
    expect(cubit.state.status, AuthStatus.signedIn);
    expect(cubit.state.user, emailUser);
    expect(cubit.state.isBusy, isFalse);
  });

  test('a wrong password shows the error and stays signed out', () async {
    await cubit.signInWithEmail('shopper@example.com', 'wrong-password');

    expect(cubit.state.status, AuthStatus.signedOut);
    expect(cubit.state.errorMessage, 'Wrong email or password.');
    expect(cubit.state.isBusy, isFalse);
  });

  test('signing up without email confirmation signs in at once', () async {
    await cubit.signUpWithEmail('new@example.com', 'secret123');

    expect(cubit.state.status, AuthStatus.signedIn);
    expect(cubit.state.user?.email, 'new@example.com');
  });

  test('signing up asks to confirm the email when Supabase requires it', () async {
    final confirming = AuthCubit(
      repository: FakeAuthRepository(confirmEmail: true),
    )..start();
    addTearDown(confirming.close);

    await confirming.signUpWithEmail('new@example.com', 'secret123');

    expect(confirming.state.status, AuthStatus.signedOut);
    expect(confirming.state.infoMessage, contains('confirmation link'));
  });

  test('GitHub opens the sign-in page; the returning session signs in', () async {
    await cubit.signInWithGitHub();
    expect(auth.gitHubRequests, 1);
    expect(cubit.state.status, AuthStatus.signedOut);
    expect(cubit.state.infoMessage, 'Finish signing in on the GitHub page.');

    auth.finishGitHubSignIn();
    await settle();
    expect(cubit.state.status, AuthStatus.signedIn);
    expect(cubit.state.user, gitHubUser);
    expect(cubit.state.user!.providerLabel, 'GitHub');
    expect(cubit.state.infoMessage, isNull);
  });

  test('a cancelled GitHub sign-in shows the reason', () async {
    await cubit.signInWithGitHub();

    auth.failGitHubSignIn('The user has denied your application access.');
    await settle();

    expect(cubit.state.status, AuthStatus.signedOut);
    expect(
      cubit.state.errorMessage,
      'The user has denied your application access.',
    );
    expect(cubit.state.infoMessage, isNull);
  });

  test('signing out goes back to signed out', () async {
    auth.finishGitHubSignIn();
    await settle();

    await cubit.signOut();

    expect(cubit.state.status, AuthStatus.signedOut);
    expect(cubit.state.user, isNull);
  });

  test('a second button press is ignored while one is running', () async {
    final first = cubit.signInWithEmail('shopper@example.com', 'secret123');
    await cubit.signInWithGitHub();
    await first;

    expect(auth.gitHubRequests, 0);
    expect(cubit.state.user, emailUser);
  });
}
