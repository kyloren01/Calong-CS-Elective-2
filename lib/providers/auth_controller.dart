import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_exception.dart';
import 'service_providers.dart';
import 'session_providers.dart';

/// The sign-in buttons, so only the one that was pressed shows a spinner.
enum AuthAction { signIn, signUp, google, signOut }

class AuthFormState {
  const AuthFormState({this.busy, this.error, this.info});

  final AuthAction? busy;
  final String? error;

  /// Guidance that isn't an error, such as "check your email".
  final String? info;

  bool get isBusy => busy != null;
}

final authControllerProvider = NotifierProvider<AuthController, AuthFormState>(
  AuthController.new,
);

/// Runs sign-in, sign-up, and sign-out. It doesn't decide which page shows:
/// the auth gate follows the session itself.
class AuthController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() {
    // Cancelling on Google's page arrives through the session stream.
    ref.listen(sessionProvider, (previous, next) {
      if (next.hasError && next.error != previous?.error) {
        state = AuthFormState(error: messageFor(next.error!));
      }
    });
    // Old messages don't matter once someone signs in or out.
    ref.listen(userIdProvider, (_, _) => state = const AuthFormState());

    final session = ref.read(sessionProvider);
    return AuthFormState(
      error: session.hasError ? messageFor(session.error!) : null,
    );
  }

  /// Whether Google sign-in can return to the app on this platform.
  bool get googleAvailable => ref.read(authServiceProvider).googleAvailable;

  Future<void> signIn({required String email, required String password}) =>
      _run(AuthAction.signIn, () async {
        await ref
            .read(authServiceProvider)
            .signIn(email: email, password: password);
        return null;
      });

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => _run(AuthAction.signUp, () async {
    final mustConfirm = await ref
        .read(authServiceProvider)
        .signUp(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
        );
    return mustConfirm
        ? 'Account created. Open the confirmation link we emailed you, then '
              'sign in.'
        : null;
  });

  Future<void> signInWithGoogle() => _run(AuthAction.google, () async {
    await ref.read(authServiceProvider).signInWithGoogle();
    return "Finish signing in on Google's page.";
  });

  Future<void> signOut() => _run(AuthAction.signOut, () async {
    await ref.read(authServiceProvider).signOut();
    return null;
  });

  /// Removes messages, for example when moving between login and sign-up.
  void clearMessages() {
    if (!state.isBusy) state = const AuthFormState();
  }

  Future<void> _run(AuthAction action, Future<String?> Function() task) async {
    if (state.isBusy) return;
    state = AuthFormState(busy: action);
    try {
      final info = await task();
      // A session event may already have replaced the state.
      if (!ref.mounted || state.busy != action) return;
      state = AuthFormState(info: info);
    } catch (error) {
      if (ref.mounted) state = AuthFormState(error: messageFor(error));
    }
  }
}
