import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_exception.dart';

const _timeout = Duration(seconds: 20);

const _networkError = AppException(
  'Could not reach Supabase. Check your internet connection and try again.',
  kind: AppErrorKind.network,
);

const _permissionError = AppException(
  "Your account doesn't have permission to do that.",
  kind: AppErrorKind.permissionDenied,
);

const _setupError = AppException(
  'The database is not set up yet. Run supabase/final_exam.sql in the '
  'Supabase SQL Editor.',
);

/// Runs a Supabase request with a time limit, and turns every Supabase or
/// network failure into an [AppException] a person can act on.
Future<T> guard<T>(Future<T> Function() request) async {
  try {
    return await request().timeout(_timeout);
  } on AppException {
    rethrow;
  } on PostgrestException catch (error) {
    throw _fromDatabase(error);
  } on StorageException catch (error) {
    throw _fromStorage(error);
  } on AuthException catch (error) {
    throw authError(error);
  } on TimeoutException {
    throw const AppException(
      'Supabase took too long to answer. Check your connection and try again.',
      kind: AppErrorKind.network,
    );
  } on ClientException {
    throw _networkError;
  }
}

AppException _fromDatabase(PostgrestException error) => switch (error.code) {
  // Refused by Row Level Security or a missing privilege.
  '42501' => _permissionError,
  // Raised by place_order(), with a message written for the customer.
  'P0001' => AppException(error.message, kind: AppErrorKind.rejected),
  '23505' => const AppException(
    'That name is already in use.',
    kind: AppErrorKind.rejected,
  ),
  '23503' => const AppException(
    'Something else still uses this, so it cannot be removed.',
    kind: AppErrorKind.rejected,
  ),
  '23514' || '23502' || '22003' => const AppException(
    'The database refused those values. Check the name, price, and stock.',
    kind: AppErrorKind.rejected,
  ),
  // A missing table, column, function, or relationship.
  '42P01' ||
  '42703' ||
  'PGRST200' ||
  'PGRST202' ||
  'PGRST204' ||
  'PGRST205' => _setupError,
  'PGRST301' || 'PGRST303' => const AppException(
    'Your session has ended. Sign out and sign in again.',
    kind: AppErrorKind.permissionDenied,
  ),
  '401' => const AppException(
    'Supabase rejected the API key. Check SUPABASE_PUBLISHABLE_KEY in '
    'supabase.json.',
  ),
  _ => AppException('Supabase error: ${error.message}'),
};

AppException _fromStorage(StorageException error) {
  final message = error.message.toLowerCase();
  // A request that never got an answer has no HTTP status.
  if (int.tryParse(error.statusCode ?? '') == null) return _networkError;
  if (error.statusCode == '403' || message.contains('row-level security')) {
    return _permissionError;
  }
  if (message.contains('bucket not found')) return _setupError;
  if (error.statusCode == '413' || message.contains('maximum allowed size')) {
    return const AppException(
      'That picture is too large. Use one under 5 MB.',
      kind: AppErrorKind.rejected,
    );
  }
  if (message.contains('mime type')) {
    return const AppException(
      'Use a JPG, PNG, WebP, or GIF picture.',
      kind: AppErrorKind.rejected,
    );
  }
  return AppException('Image storage error: ${error.message}');
}

/// A message for a sign-in or session error. Also used for the errors that
/// arrive through the session stream, such as cancelling on Google's page.
AppException authError(Object error) {
  if (error is AppException) return error;
  if (error is AuthRetryableFetchException || error is ClientException) {
    return _networkError;
  }
  if (error is! AuthException) return AppException('Sign-in failed: $error');
  return AppException(switch (error.code) {
    'invalid_credentials' => 'Wrong email or password.',
    'email_not_confirmed' =>
      'Confirm your email first. Open the link Supabase emailed you, then '
          'sign in.',
    'user_already_exists' ||
    'email_exists' => 'That email already has an account. Sign in instead.',
    'over_email_send_rate_limit' =>
      'Supabase sent too many emails. Wait a few minutes, or turn off '
          '"Confirm email" in Supabase while testing.',
    'email_provider_disabled' => 'Email sign-in is turned off in Supabase.',
    'signup_disabled' => 'Supabase is not accepting new sign-ups.',
    _ when error.message.contains('provider is not enabled') =>
      'Google sign-in is not turned on in Supabase yet.',
    // Raised when the handle_new_user trigger fails.
    _ when error.message.contains('Database error saving new user') =>
      'Supabase could not create your profile. Run supabase/final_exam.sql '
          'in the Supabase SQL Editor.',
    _ => error.message,
  });
}
