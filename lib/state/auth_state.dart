import '../models/app_user.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// The sign-in buttons, so only the one that was pressed shows a spinner.
enum AuthAction { emailSignIn, emailSignUp, gitHub, signOut }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.busy,
    this.errorMessage,
    this.infoMessage,
  });

  final AuthStatus status;
  final AppUser? user;

  /// The action waiting for Supabase, or null when nothing is.
  final AuthAction? busy;

  final String? errorMessage;

  /// Guidance that isn't an error, such as "check your email".
  final String? infoMessage;

  bool get isBusy => busy != null;

  /// [clearMessages] removes the current messages; any message passed in
  /// the same call is still shown.
  AuthState copyWith({
    AuthAction? busy,
    bool clearBusy = false,
    String? errorMessage,
    String? infoMessage,
    bool clearMessages = false,
  }) => AuthState(
    status: status,
    user: user,
    busy: clearBusy ? null : busy ?? this.busy,
    errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
    infoMessage: infoMessage ?? (clearMessages ? null : this.infoMessage),
  );
}
