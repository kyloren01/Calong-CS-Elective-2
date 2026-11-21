import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_ui/config/supabase_config.dart';
import 'package:my_first_flutter_ui/data/auth_repository.dart';
import 'package:my_first_flutter_ui/data/supabase_auth_repository.dart';
import 'package:my_first_flutter_ui/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the PKCE code verifier in memory, as the browser or app storage
/// would.
class _MemoryStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _items[key] = value;

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);
}

/// These tests run the real Supabase Auth client and answer its HTTP
/// requests here, so they check what the app actually sends.
void main() {
  late List<http.Request> requests;
  SupabaseClient? client;

  SupabaseAuthRepository repositoryWith(
    Future<http.Response> Function(http.Request request) answer,
  ) {
    requests = [];
    client = SupabaseClient(
      'https://demo.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await answer(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _MemoryStorage(),
      ),
    );
    return SupabaseAuthRepository(client!.auth);
  }

  tearDown(() async {
    await client?.dispose();
    client = null;
  });

  http.Response json(Object body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Map<String, Object?> userJson({
    String id = 'user-1',
    String provider = 'email',
    Map<String, Object?> metadata = const {},
    bool hasIdentity = true,
  }) => {
    'id': id,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'shopper@example.com',
    'app_metadata': {
      'provider': provider,
      'providers': [provider],
    },
    'user_metadata': metadata,
    'created_at': '2026-11-21T00:00:00Z',
    'identities': [
      if (hasIdentity)
        {
          'id': 'identity-1',
          'identity_id': 'identity-1',
          'user_id': id,
          'provider': provider,
          'identity_data': {'sub': id},
          'created_at': '2026-11-21T00:00:00Z',
          'last_sign_in_at': '2026-11-21T00:00:00Z',
          'updated_at': '2026-11-21T00:00:00Z',
        },
    ],
  };

  Map<String, Object?> sessionJson(Map<String, Object?> user) {
    String part(Map<String, Object?> data) =>
        base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
    final expiresAt =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000;
    final token = [
      part({'alg': 'HS256', 'typ': 'JWT'}),
      part({
        'sub': user['id'],
        'exp': expiresAt,
        'role': 'authenticated',
        'aud': 'authenticated',
      }),
      'signature',
    ].join('.');
    return {
      'access_token': token,
      'token_type': 'bearer',
      'expires_in': 3600,
      'expires_at': expiresAt,
      'refresh_token': 'refresh-token',
      'user': user,
    };
  }

  test('email sign-in sends the password grant and reports the user', () async {
    final repository = repositoryWith((_) async => json(sessionJson(userJson())));
    final users = <AppUser?>[];
    final subscription = repository.userChanges.listen(users.add);
    addTearDown(subscription.cancel);

    await repository.signInWithEmail(
      email: 'shopper@example.com',
      password: 'secret123',
    );
    await Future<void>.delayed(Duration.zero);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/auth/v1/token');
    expect(request.url.queryParameters['grant_type'], 'password');
    expect(jsonDecode(request.body), containsPair('email', 'shopper@example.com'));
    const expected = AppUser(
      id: 'user-1',
      provider: 'email',
      email: 'shopper@example.com',
    );
    expect(repository.currentUser, expected);
    expect(users.last, expected);
  });

  test('a wrong password becomes a readable message', () async {
    final repository = repositoryWith(
      (_) async => json({
        'code': 400,
        'error_code': 'invalid_credentials',
        'msg': 'Invalid login credentials',
      }, status: 400),
    );

    await expectLater(
      repository.signInWithEmail(email: 'shopper@example.com', password: 'x'),
      throwsA(
        isA<AuthRepositoryException>().having(
          (error) => error.message,
          'message',
          'Wrong email or password.',
        ),
      ),
    );
  });

  test('sign-up reports when the email must be confirmed first', () async {
    // With "Confirm email" on, Supabase returns the user without a session.
    final repository = repositoryWith((_) async => json(userJson()));

    final mustConfirm = await repository.signUpWithEmail(
      email: 'shopper@example.com',
      password: 'secret123',
    );

    expect(mustConfirm, isTrue);
    final request = requests.single;
    expect(request.url.path, '/auth/v1/signup');
    expect(
      request.url.queryParameters['redirect_to'],
      SupabaseConfig.mobileRedirectUrl,
    );
    expect(repository.currentUser, isNull);
  });

  test('sign-up with a session signs in straight away', () async {
    final repository = repositoryWith((_) async => json(sessionJson(userJson())));

    final mustConfirm = await repository.signUpWithEmail(
      email: 'shopper@example.com',
      password: 'secret123',
    );

    expect(mustConfirm, isFalse);
    expect(repository.currentUser?.email, 'shopper@example.com');
  });

  test('sign-up spots an email that already has an account', () async {
    final repository = repositoryWith(
      (_) async => json(userJson(hasIdentity: false)),
    );

    await expectLater(
      repository.signUpWithEmail(
        email: 'shopper@example.com',
        password: 'secret123',
      ),
      throwsA(
        isA<AuthRepositoryException>().having(
          (error) => error.message,
          'message',
          contains('already has an account'),
        ),
      ),
    );
  });

  test('sign-out ends the session', () async {
    final repository = repositoryWith(
      (request) async => request.url.path.endsWith('/logout')
          ? http.Response('', 204)
          : json(sessionJson(userJson())),
    );
    await repository.signInWithEmail(
      email: 'shopper@example.com',
      password: 'secret123',
    );
    expect(repository.currentUser, isNotNull);

    await repository.signOut();

    expect(requests.last.url.path, '/auth/v1/logout');
    expect(repository.currentUser, isNull);
  });

  test('no internet becomes a readable message', () async {
    final repository = repositoryWith(
      (_) async => throw http.ClientException('Failed host lookup'),
    );

    await expectLater(
      repository.signInWithEmail(email: 'shopper@example.com', password: 'x'),
      throwsA(
        isA<AuthRepositoryException>().having(
          (error) => error.message,
          'message',
          contains('Could not reach Supabase'),
        ),
      ),
    );
  });

  test('the GitHub page is asked to come back to the app', () async {
    repositoryWith((_) async => json({}));

    final response = await client!.auth.getOAuthSignInUrl(
      provider: OAuthProvider.github,
      redirectTo: authRedirectUrl,
    );

    final url = Uri.parse(response.url);
    expect(url.path, '/auth/v1/authorize');
    expect(url.queryParameters['provider'], 'github');
    expect(url.queryParameters['redirect_to'], 'io.supabase.shopping://login-callback/');
    expect(url.queryParameters['code_challenge_method'], 's256');
  });

  test('GitHub sign-in is offered on Android and iOS, not desktop', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final expected = {
      TargetPlatform.android: true,
      TargetPlatform.iOS: true,
      TargetPlatform.windows: false,
      TargetPlatform.macOS: false,
      TargetPlatform.linux: false,
    };
    for (final MapEntry(key: platform, value: available) in expected.entries) {
      debugDefaultTargetPlatformOverride = platform;
      expect(gitHubRedirectSupported, available, reason: '$platform');
    }
  });

  test('a GitHub account shows its name and picture', () {
    final user = User.fromJson(
      userJson(
        id: 'user-2',
        provider: 'github',
        metadata: {
          'full_name': 'Octo Cat',
          'user_name': 'octocat',
          'avatar_url': 'https://avatars.githubusercontent.com/u/583231',
        },
      ),
    )!;

    expect(
      appUserFrom(user),
      const AppUser(
        id: 'user-2',
        provider: 'github',
        email: 'shopper@example.com',
        name: 'Octo Cat',
        avatarUrl: 'https://avatars.githubusercontent.com/u/583231',
      ),
    );
  });

  test('a GitHub provider that is off in Supabase gets a clear message', () {
    expect(
      describeAuthError(
        const AuthException(
          'Unsupported provider: provider is not enabled',
          statusCode: '400',
          code: 'validation_failed',
        ),
      ),
      contains('GitHub sign-in is not turned on in Supabase'),
    );
  });
}
