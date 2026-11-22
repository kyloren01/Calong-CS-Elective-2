import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/app_exception.dart';
import '../models/session_user.dart';
import 'supabase_guard.dart';

/// Email + password and Google sign-in with Supabase Auth.
class AuthService {
  AuthService(this._auth);

  final GoTrueClient _auth;

  /// The signed-in account: first the saved session, then every sign-in and
  /// sign-out, including the browser coming back from Google.
  Stream<SessionUser?> get userChanges => _auth.onAuthStateChange.transform(
    StreamTransformer.fromHandlers(
      handleData: (state, sink) =>
          sink.add(_toSessionUser(state.session?.user)),
      // For example, pressing Cancel on Google's page ends up here.
      handleError: (error, stackTrace, sink) =>
          sink.addError(authError(error), stackTrace),
    ),
  );

  /// Whether this platform can return from Google's sign-in page.
  bool get googleAvailable => googleRedirectSupported;

  Future<void> signIn({required String email, required String password}) =>
      guard(() => _auth.signInWithPassword(email: email, password: password));

  /// Creates an account. Returns true when the person must first confirm
  /// their email (Supabase's "Confirm email" setting).
  ///
  /// The names travel as metadata; the handle_new_user trigger copies them
  /// into the profile. The role is never sent: the database picks it.
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => guard(() async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'firstname': firstName, 'lastname': lastName},
      emailRedirectTo: authRedirectUrl,
    );
    // While "Confirm email" is on, Supabase doesn't reveal whether an email
    // is taken. An existing account comes back with no identities instead.
    if (response.user?.identities?.isEmpty ?? false) {
      throw const AppException(
        'That email already has an account. Sign in instead.',
      );
    }
    return response.session == null;
  });

  /// Opens Google's sign-in page. The session arrives later, through
  /// [userChanges].
  Future<void> signInWithGoogle() => guard(() async {
    final opened = await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirectUrl,
      // Google doesn't allow sign-in inside an app's own web view.
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      // Lets people switch accounts after signing out.
      queryParams: const {'prompt': 'select_account'},
    );
    if (!opened) {
      throw const AppException('Could not open the Google sign-in page.');
    }
  });

  Future<void> signOut() => guard(() async {
    try {
      await _auth.signOut();
    } on AuthException {
      // Without internet, Supabase still forgets the session on this device,
      // so the person is signed out. Only report it when that failed too.
      if (_auth.currentSession != null) rethrow;
    }
  });

  static SessionUser? _toSessionUser(User? user) =>
      user == null ? null : SessionUser(id: user.id, email: user.email);
}

/// Where Supabase sends the browser after Google approves the sign-in. It
/// must be listed in Supabase under Authentication → URL Configuration.
String get authRedirectUrl =>
    kIsWeb ? '${Uri.base.origin}/' : SupabaseConfig.mobileRedirectUrl;

/// Google sign-in needs a way back into the app: the same browser tab on
/// web, or a deep link on Android and iOS. Desktop apps would need the link
/// registered with the operating system, which this project skips.
bool get googleRedirectSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;
