import 'dart:async';

import 'package:my_first_flutter_ui/data/auth_repository.dart';
import 'package:my_first_flutter_ui/models/app_user.dart';

const emailUser = AppUser(
  id: 'email-shopper@example.com',
  provider: 'email',
  email: 'shopper@example.com',
);

const gitHubUser = AppUser(
  id: 'github-octocat',
  provider: 'github',
  email: 'octocat@example.com',
  name: 'Octo Cat',
);

/// An in-memory Supabase Auth with one email account. A GitHub sign-in
/// finishes when the test calls [finishGitHubSignIn], like the browser
/// coming back from GitHub.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AppUser? signedIn,
    this.gitHubAvailable = true,
    this.confirmEmail = false,
  }) : _user = signedIn;

  final _changes = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// Email accounts and their passwords.
  final Map<String, String> passwords = {'shopper@example.com': 'secret123'};

  @override
  final bool gitHubAvailable;

  /// Like Supabase's "Confirm email" setting.
  final bool confirmEmail;

  int gitHubRequests = 0;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _changes.stream;

  void _signIn(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (passwords[email] != password) {
      throw const AuthRepositoryException('Wrong email or password.');
    }
    _signIn(AppUser(id: 'email-$email', provider: 'email', email: email));
  }

  @override
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (passwords.containsKey(email)) {
      throw const AuthRepositoryException(
        'That email already has an account. Sign in instead.',
      );
    }
    passwords[email] = password;
    if (confirmEmail) return true;
    _signIn(AppUser(id: 'email-$email', provider: 'email', email: email));
    return false;
  }

  @override
  Future<void> signInWithGitHub() async {
    await Future<void>.delayed(Duration.zero);
    gitHubRequests++;
  }

  /// The browser came back from GitHub with a session.
  void finishGitHubSignIn([AppUser user = gitHubUser]) => _signIn(user);

  /// The browser came back from GitHub with an error, such as Cancel.
  void failGitHubSignIn(String message) =>
      _changes.addError(AuthRepositoryException(message));

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(Duration.zero);
    _signIn(null);
  }
}
