import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

/// Email + password and GitHub sign-in with Supabase Auth.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final GoTrueClient _auth;

  @override
  AppUser? get currentUser => appUserFrom(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges => _auth.onAuthStateChange.transform(
    StreamTransformer.fromHandlers(
      handleData: (state, sink) => sink.add(appUserFrom(state.session?.user)),
      // For example, pressing Cancel on the GitHub page ends up here.
      handleError: (error, stackTrace, sink) => sink.addError(
        AuthRepositoryException(describeAuthError(error)),
        stackTrace,
      ),
    ),
  );

  @override
  bool get gitHubAvailable => gitHubRedirectSupported;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() => _auth.signInWithPassword(email: email, password: password));

  @override
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: authRedirectUrl,
    );
    // While "Confirm email" is on, Supabase doesn't reveal whether an email
    // is taken. An existing account comes back with no identities instead.
    if (response.user?.identities?.isEmpty ?? false) {
      throw const AuthRepositoryException(
        'That email already has an account. Sign in instead.',
      );
    }
    return response.session == null;
  });

  @override
  Future<void> signInWithGitHub() => _guard(() async {
    // On web this leaves the page; Supabase brings the browser back to
    // [authRedirectUrl] with a code, and supabase_flutter signs in with it.
    final opened = await _auth.signInWithOAuth(
      OAuthProvider.github,
      redirectTo: authRedirectUrl,
    );
    if (!opened) {
      throw const AuthRepositoryException(
        'Could not open the GitHub sign-in page.',
      );
    }
  });

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthRepositoryException {
      rethrow;
    } on AuthException catch (error) {
      throw AuthRepositoryException(describeAuthError(error));
    } on ClientException catch (error) {
      throw AuthRepositoryException(describeAuthError(error));
    }
  }
}

/// Where Supabase sends the browser after GitHub approves the sign-in.
/// It must be listed in Supabase under Authentication → URL Configuration.
String get authRedirectUrl =>
    kIsWeb ? '${Uri.base.origin}/' : SupabaseConfig.mobileRedirectUrl;

/// GitHub sign-in needs a way back into the app: the same browser tab on
/// web, or a deep link on Android and iOS. Desktop apps would need the link
/// scheme registered with the operating system, which this project skips.
bool get gitHubRedirectSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Turns a Supabase user into the app's [AppUser].
AppUser? appUserFrom(User? user) {
  if (user == null) return null;
  final profile = user.userMetadata ?? const {};
  String? text(String key) {
    final value = profile[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  return AppUser(
    id: user.id,
    provider: user.appMetadata['provider'] as String? ?? 'email',
    email: user.email,
    // GitHub fills these in; email accounts leave them empty.
    name: text('full_name') ?? text('name') ?? text('user_name'),
    avatarUrl: text('avatar_url'),
  );
}

/// A message a person can act on, for a Supabase Auth error.
String describeAuthError(Object error) {
  if (error is AuthRetryableFetchException || error is ClientException) {
    return 'Could not reach Supabase. Check your internet connection and try again.';
  }
  if (error is! AuthException) return 'Sign-in failed: $error';
  return switch (error.code) {
    'invalid_credentials' => 'Wrong email or password.',
    'email_not_confirmed' =>
      'Confirm your email first. Open the link Supabase emailed you, then sign in.',
    'user_already_exists' ||
    'email_exists' => 'That email already has an account. Sign in instead.',
    'over_email_send_rate_limit' =>
      'Supabase sent too many emails. Wait a few minutes, or turn off '
          '"Confirm email" in Supabase while testing.',
    'email_provider_disabled' =>
      'Email sign-in is turned off in Supabase '
          '(Authentication → Sign In / Providers → Email).',
    'signup_disabled' => 'Supabase is not accepting new sign-ups.',
    _ when error.message.contains('provider is not enabled') =>
      'GitHub sign-in is not turned on in Supabase yet '
          '(Authentication → Sign In / Providers → GitHub).',
    _ => error.message,
  };
}
