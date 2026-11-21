import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../models/app_user.dart';
import 'auth_state.dart';

/// Follows the Supabase session and runs the sign-in and sign-out actions.
/// The screen changes as soon as Supabase reports a new session, whether it
/// came from the email form or back from the GitHub page.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this.repository}) : super(const AuthState());

  final AuthRepository repository;
  StreamSubscription<AppUser?>? _subscription;

  /// False on desktop, where the browser can't hand the session back.
  bool get gitHubAvailable => repository.gitHubAvailable;

  /// Restores a saved session, then listens for sign-ins and sign-outs.
  void start() {
    _setUser(repository.currentUser);
    _subscription ??= repository.userChanges.listen(
      _setUser,
      onError: (Object error) => _showError(error),
    );
  }

  Future<void> signInWithEmail(String email, String password) =>
      _run(AuthAction.emailSignIn, () async {
        await repository.signInWithEmail(email: email, password: password);
        return null;
      });

  Future<void> signUpWithEmail(String email, String password) =>
      _run(AuthAction.emailSignUp, () async {
        final mustConfirm = await repository.signUpWithEmail(
          email: email,
          password: password,
        );
        return mustConfirm
            ? 'Account created. Open the confirmation link Supabase emailed '
                  'you, then sign in.'
            : null;
      });

  Future<void> signInWithGitHub() => _run(AuthAction.gitHub, () async {
    await repository.signInWithGitHub();
    return 'Finish signing in on the GitHub page.';
  });

  Future<void> signOut() => _run(AuthAction.signOut, () async {
    await repository.signOut();
    return null;
  });

  /// Shows [action] as busy while [task] runs. [task] may return guidance to
  /// show afterwards.
  Future<void> _run(AuthAction action, Future<String?> Function() task) async {
    if (isClosed || state.isBusy) return;
    emit(state.copyWith(busy: action, clearMessages: true));
    try {
      final info = await task();
      if (isClosed) return;
      // Show the result right away instead of waiting for the stream event.
      _setUser(repository.currentUser);
      emit(state.copyWith(clearBusy: true, infoMessage: info));
    } catch (error) {
      _showError(error);
    }
  }

  void _setUser(AppUser? user) {
    if (isClosed) return;
    final status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    // Token refreshes repeat the same user; they shouldn't reset the screen.
    if (status == state.status && user == state.user) return;
    emit(AuthState(status: status, user: user));
  }

  void _showError(Object error) {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearBusy: true,
        clearMessages: true,
        errorMessage: error is AuthRepositoryException
            ? error.message
            : 'Something went wrong: $error',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
