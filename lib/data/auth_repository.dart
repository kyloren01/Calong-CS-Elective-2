import '../models/app_user.dart';

/// Signing in and out. The app uses [SupabaseAuthRepository]; the tests use
/// an in-memory fake.
abstract class AuthRepository {
  /// Who is signed in right now. A saved session is restored at startup.
  AppUser? get currentUser;

  /// Emits whenever someone signs in or out, including when the browser
  /// comes back from the GitHub sign-in page.
  Stream<AppUser?> get userChanges;

  /// Whether this platform can return from the GitHub sign-in page.
  bool get gitHubAvailable;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates an email account. Returns true when the person must first
  /// confirm their email (Supabase's "Confirm email" setting).
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Opens the GitHub sign-in page. The new session arrives later through
  /// [userChanges].
  Future<void> signInWithGitHub();

  Future<void> signOut();
}

/// A sign-in failure whose [message] can be shown to the person.
class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
