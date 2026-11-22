import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_ui/config/supabase_config.dart';
import 'package:my_first_flutter_ui/models/app_exception.dart';
import 'package:my_first_flutter_ui/models/cart.dart';
import 'package:my_first_flutter_ui/models/catalog.dart';
import 'package:my_first_flutter_ui/models/order.dart';
import 'package:my_first_flutter_ui/models/picked_image.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/models/profile.dart';
import 'package:my_first_flutter_ui/models/session_user.dart';
import 'package:my_first_flutter_ui/services/auth_service.dart';
import 'package:my_first_flutter_ui/services/category_service.dart';
import 'package:my_first_flutter_ui/services/image_picker_service.dart';
import 'package:my_first_flutter_ui/services/image_service.dart';
import 'package:my_first_flutter_ui/services/order_service.dart';
import 'package:my_first_flutter_ui/services/product_service.dart';
import 'package:my_first_flutter_ui/services/profile_service.dart';
import 'package:my_first_flutter_ui/services/supabase_guard.dart';
import 'package:my_first_flutter_ui/utils/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the sign-in code verifier in memory, as the app's storage would.
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

/// These tests run the real Supabase client and answer its HTTP requests
/// here, so they check exactly what the app sends.
void main() {
  late List<http.Request> requests;
  late SupabaseClient client;
  var opened = false;

  SupabaseClient open(Future<http.Response> Function(http.Request) answer) {
    requests = [];
    opened = true;
    return client = SupabaseClient(
      'https://demo.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await answer(request);
        // Real clients attach the request to the response.
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          reasonPhrase: response.reasonPhrase,
          request: request,
        );
      }),
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _MemoryStorage(),
      ),
    );
  }

  tearDown(() async {
    if (opened) await client.dispose();
    opened = false;
  });

  http.Response json(
    Object body, {
    int status = 200,
    Map<String, String> headers = const {},
  }) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json', ...headers},
  );

  Matcher fails(AppErrorKind kind, [Object message = anything]) => throwsA(
    isA<AppException>()
        .having((error) => error.kind, 'kind', kind)
        .having((error) => error.message, 'message', message),
  );

  const productRow = {
    'id': 3,
    'name': 'Pulse Earbuds',
    'description': null,
    'price': 89,
    'stock': 18,
    'category_id': 1,
    'image_path': 'a.png',
    'categories': {'name': 'Audio'},
  };
  const columns =
      'id,name,description,price,stock,category_id,image_path,categories(name)';
  const draft = ProductDraft(
    name: 'Desk Mat',
    description: 'Soft felt.',
    price: 12.5,
    stock: 3,
    categoryId: 4,
    imagePath: 'mat.png',
  );

  group('products', () {
    test('one query carries search, category, price, order, and page', () async {
      final service = ProductService(
        open(
          (_) async => json(
            [productRow],
            status: 206,
            headers: {'content-range': '6-6/7'},
          ),
        ),
      );
      final page = await service.fetchPage(
        const CatalogFilters(
          search: 'pulse',
          categoryId: 1,
          price: PriceRange(40, 130),
          page: 2,
        ),
      );

      final request = requests.single;
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/products');
      expect(request.url.queryParametersAll, {
        'select': [columns],
        'name': ['ilike.%pulse%'],
        'category_id': ['eq.1'],
        'price': ['gte.40.0', 'lte.130.0'],
        'order': ['price.asc.nullslast,id.asc.nullslast'],
        'offset': ['6'],
        'limit': ['6'],
      });
      expect(request.headers['Prefer'], contains('count=exact'));
      expect(page.totalCount, 7);
      expect(page.page, 2);
      final product = page.products.single;
      expect(product.price, 89.0);
      expect(product.description, '');
      expect(product.categoryName, 'Audio');
      expect(
        product.imageUrl,
        'https://demo.supabase.co/storage/v1/object/public/product-images/a.png',
      );
    });

    test('without filters, none are sent', () async {
      final service = ProductService(
        open((_) async => json([], headers: {'content-range': '*/0'})),
      );
      await service.fetchPage(const CatalogFilters());
      expect(
        requests.single.url.queryParameters.keys,
        unorderedEquals(['select', 'order', 'offset', 'limit']),
      );
    });

    test('wildcards typed in the search box are searched literally', () async {
      final service = ProductService(
        open((_) async => json([], headers: {'content-range': '*/0'})),
      );
      await service.fetchPage(const CatalogFilters(search: r'50%_off\'));
      expect(
        requests.single.url.queryParameters['name'],
        r'ilike.%50\%\_off\\%',
      );
    });

    test('a page past the end shows the last page', () async {
      final service = ProductService(
        open((request) async {
          if (request.method == 'HEAD') {
            return http.Response('', 200, headers: {'content-range': '0-5/6'});
          }
          if (request.url.queryParameters['offset'] == '0') {
            return json(
              [productRow],
              status: 206,
              headers: {'content-range': '0-0/6'},
            );
          }
          return json({
            'code': 'PGRST103',
            'message': 'Requested range not satisfiable',
            'details':
                'An offset of 6 was requested, but there are only 6 rows.',
          }, status: 416);
        }),
      );
      final page = await service.fetchPage(const CatalogFilters(page: 2));
      expect(page.page, 1);
      expect(page.products, hasLength(1));
      expect(requests.map((r) => r.method), ['GET', 'HEAD', 'GET']);
    });

    test('price limits come from the cheapest and priciest product', () async {
      final service = ProductService(
        open((request) async {
          final cheapest = request.url.queryParameters['order']!.startsWith(
            'price.asc',
          );
          return json([
            {'price': cheapest ? 18 : 249.5},
          ]);
        }),
      );
      expect(await service.fetchPriceBounds(), const PriceRange(18, 249.5));
    });

    test('an empty shop has no price limits', () async {
      final service = ProductService(open((_) async => json([])));
      expect(await service.fetchPriceBounds(), isNull);
    });

    test('the cart asks for its own products', () async {
      final service = ProductService(open((_) async => json([productRow])));
      final products = await service.fetchByIds([3, 7]);
      expect(requests.single.url.queryParameters['id'], 'in.(3,7)');
      expect(products.single.name, 'Pulse Earbuds');

      expect(await service.fetchByIds([]), isEmpty);
      expect(requests, hasLength(1));
    });

    test('add, edit, and delete', () async {
      final service = ProductService(
        open(
          (request) async => request.method == 'POST'
              ? http.Response('', 201)
              : json([
                  {'id': 7},
                ]),
        ),
      );
      await service.create(draft);
      await service.update(7, draft);
      await service.delete(7);
      expect(requests.map((r) => r.method), ['POST', 'PATCH', 'DELETE']);
      expect(jsonDecode(requests[0].body), {
        'name': 'Desk Mat',
        'description': 'Soft felt.',
        'price': 12.5,
        'stock': 3,
        'category_id': 4,
        'image_path': 'mat.png',
      });
      expect(requests[1].url.queryParameters, {'id': 'eq.7', 'select': 'id'});
      expect(requests[2].url.queryParameters, {'id': 'eq.7', 'select': 'id'});
    });

    test('RLS hiding the row counts as permission denied', () async {
      final service = ProductService(open((_) async => json([])));
      await expectLater(
        service.update(7, draft),
        fails(AppErrorKind.permissionDenied),
      );
      await expectLater(
        service.delete(7),
        fails(AppErrorKind.permissionDenied),
      );
    });
  });

  group('categories', () {
    test('listed A to Z', () async {
      final service = CategoryService(
        open(
          (_) async => json([
            {'id': 1, 'name': 'Audio'},
          ]),
        ),
      );
      expect((await service.fetchAll()).single.name, 'Audio');
      expect(
        requests.single.url.queryParameters['order'],
        'name.asc.nullslast',
      );
    });

    test('add, rename, and delete', () async {
      final service = CategoryService(
        open(
          (request) async => request.method == 'POST'
              ? http.Response('', 201)
              : json([
                  {'id': 2},
                ]),
        ),
      );
      await service.add('Garden');
      await service.rename(2, 'Outdoor');
      await service.delete(2);
      expect(jsonDecode(requests[0].body), {'name': 'Garden'});
      expect(jsonDecode(requests[1].body), {'name': 'Outdoor'});
      expect(requests[2].method, 'DELETE');
    });

    test('deleting one that is in use explains why', () async {
      final service = CategoryService(
        open(
          (_) async => json({
            'code': '23503',
            'message': 'violates foreign key constraint',
          }, status: 409),
        ),
      );
      await expectLater(
        service.delete(1),
        fails(AppErrorKind.rejected, contains('still has products')),
      );
    });

    test('a customer is refused', () async {
      final service = CategoryService(
        open(
          (_) async => json({
            'code': '42501',
            'message': 'new row violates row-level security policy',
          }, status: 403),
        ),
      );
      await expectLater(
        service.add('Garden'),
        fails(AppErrorKind.permissionDenied),
      );
    });
  });

  group('profiles', () {
    test('loaded with the name of the role', () async {
      final service = ProfileService(
        open(
          (_) async => json([
            {
              'id': 'u1',
              'email': 'ana@example.com',
              'firstname': 'Ana',
              'lastname': 'Cruz',
              'roles': {'role': 'admin'},
            },
          ]),
        ),
      );
      final profile = await service.fetchProfile('u1');
      expect(profile!.role, UserRole.admin);
      expect(profile.fullName, 'Ana Cruz');
      expect(
        requests.single.url.queryParameters['select'],
        'id,email,firstname,lastname,roles(role)',
      );
      expect(requests.single.url.queryParameters['id'], 'eq.u1');
    });

    test('a missing profile is null', () async {
      final service = ProfileService(open((_) async => json([])));
      expect(await service.fetchProfile('u1'), isNull);
    });

    test('only the name is ever sent, never the role', () async {
      final service = ProfileService(
        open(
          (_) async => json([
            {'id': 'u1'},
          ]),
        ),
      );
      await service.updateName('u1', firstName: 'Anna', lastName: 'Cruz');
      expect(jsonDecode(requests.single.body), {
        'firstname': 'Anna',
        'lastname': 'Cruz',
      });
    });
  });

  group('orders', () {
    const line = CartLine(
      product: Product(
        id: 3,
        name: 'Pulse Earbuds',
        price: 89,
        stock: 18,
        categoryId: 1,
        categoryName: 'Audio',
      ),
      quantity: 2,
    );
    const savedOrder = {
      'id': 42,
      'status': 'done',
      'total': 178.00,
      'created_at': '2026-11-22T07:05:00+00:00',
      'order_items': [
        {'product_name': 'Pulse Earbuds', 'unit_price': 89, 'quantity': 2},
      ],
    };

    test('checkout sends only product ids and quantities', () async {
      final service = OrderService(open((_) async => json(savedOrder)));
      final order = await service.placeOrder([line]);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.path, '/rest/v1/rpc/place_order');
      expect(jsonDecode(request.body), {
        'items': [
          {'product_id': 3, 'quantity': 2},
        ],
      });
      expect(order.number, '#00042');
      expect(order.status, OrderStatus.done);
      expect(order.total, 178);
      expect(order.items.single.productName, 'Pulse Earbuds');
      expect(order.itemCount, 2);
    });

    test("the database's reason is shown as it is", () async {
      final service = OrderService(
        open(
          (_) async => json({
            'code': 'P0001',
            'message': 'Only 1 left of Pulse Earbuds.',
          }, status: 400),
        ),
      );
      await expectLater(
        service.placeOrder([line]),
        fails(AppErrorKind.rejected, 'Only 1 left of Pulse Earbuds.'),
      );
    });

    test('a lost answer tells the customer to check Orders first', () async {
      final service = OrderService(
        open((_) async => throw http.ClientException('Connection closed')),
      );
      await expectLater(
        service.placeOrder([line]),
        fails(AppErrorKind.network, contains('check Orders')),
      );
      // Placing an order must never be retried automatically.
      expect(requests, hasLength(1));
    });

    test("a customer's orders: own rows only, newest first", () async {
      final service = OrderService(open((_) async => json([savedOrder])));
      final orders = await service.fetchMyOrders('u1');
      final query = requests.single.url.queryParameters;
      expect(query['user_id'], 'eq.u1');
      expect(query['order'], 'created_at.desc.nullslast,id.desc.nullslast');
      expect(orders.single.items, hasLength(1));
    });

    test("the admin's list includes the customer", () async {
      final service = OrderService(
        open(
          (_) async => json([
            {
              ...savedOrder,
              'profiles': {
                'email': 'ana@example.com',
                'firstname': 'Ana',
                'lastname': 'Cruz',
              },
            },
          ]),
        ),
      );
      final order = (await service.fetchAllOrders()).single;
      expect(order.customerName, 'Ana Cruz');
      expect(order.customerEmail, 'ana@example.com');
      expect(
        requests.single.url.queryParameters['select'],
        contains('profiles(email,firstname,lastname)'),
      );
    });

    test('only the status is updated', () async {
      final service = OrderService(
        open(
          (_) async => json([
            {'id': 42},
          ]),
        ),
      );
      await service.updateStatus(42, OrderStatus.cancelled);
      expect(requests.single.method, 'PATCH');
      expect(jsonDecode(requests.single.body), {'status': 'cancelled'});

      client = open((_) async => json([]));
      await expectLater(
        OrderService(client).updateStatus(42, OrderStatus.done),
        fails(AppErrorKind.permissionDenied),
      );
    });
  });

  group('images', () {
    final image = PickedImage(
      bytes: Uint8List.fromList([1, 2, 3]),
      extension: 'png',
      contentType: 'image/png',
    );

    test('uploaded to the bucket under a new name', () async {
      final service = ImageService(
        open((_) async => json({'Key': 'product-images/x.png', 'Id': '1'})),
      );
      final path = await service.upload(image);
      final other = await service.upload(image);
      expect(path, endsWith('.png'));
      expect(other, isNot(path));
      expect(requests.first.method, 'POST');
      expect(
        requests.first.url.path,
        '/storage/v1/object/product-images/$path',
      );
    });

    test('deleted by path', () async {
      final service = ImageService(open((_) async => json([])));
      await service.delete('a.png');
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/storage/v1/object/product-images');
      expect(jsonDecode(requests.single.body), {
        'prefixes': ['a.png'],
      });
    });

    test('a customer, a missing bucket, and no internet', () async {
      Future<void> upload(Future<http.Response> Function() answer) =>
          ImageService(open((_) => answer())).upload(image);
      await expectLater(
        upload(
          () async => json({
            'statusCode': '403',
            'error': 'Unauthorized',
            'message': 'new row violates row-level security policy',
          }, status: 400),
        ),
        fails(AppErrorKind.permissionDenied),
      );
      await expectLater(
        upload(
          () async => json({
            'statusCode': '404',
            'error': 'Bucket not found',
            'message': 'Bucket not found',
          }, status: 400),
        ),
        fails(AppErrorKind.unknown, contains('final_exam.sql')),
      );
      await expectLater(
        upload(() async => throw http.ClientException('offline')),
        fails(AppErrorKind.network),
      );
    });

    test('only pictures Storage accepts can be chosen', () {
      PickedImage picked(String extension, String type, [int size = 10]) =>
          PickedImage(
            bytes: Uint8List(size),
            extension: extension,
            contentType: type,
          );
      expect(
        ImagePickerService.check(picked('JPG'.toLowerCase(), '')).contentType,
        'image/jpeg',
      );
      expect(
        ImagePickerService.check(picked('bin', 'image/webp')).extension,
        'webp',
      );
      expect(
        () => ImagePickerService.check(picked('pdf', 'application/pdf')),
        fails(AppErrorKind.rejected, contains('JPG')),
      );
      expect(
        () => ImagePickerService.check(
          picked('png', 'image/png', ImagePickerService.maxBytes + 1),
        ),
        fails(AppErrorKind.rejected, contains('5 MB')),
      );
    });
  });

  group('sign-in', () {
    Map<String, Object?> user({bool hasIdentity = true}) => {
      'id': 'user-1',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'ana@example.com',
      'app_metadata': {
        'provider': 'email',
        'providers': ['email'],
      },
      'user_metadata': <String, Object?>{},
      'created_at': '2026-11-22T00:00:00Z',
      'identities': [
        if (hasIdentity)
          {
            'id': 'identity-1',
            'identity_id': 'identity-1',
            'user_id': 'user-1',
            'provider': 'email',
            'identity_data': {'sub': 'user-1'},
            'created_at': '2026-11-22T00:00:00Z',
            'last_sign_in_at': '2026-11-22T00:00:00Z',
            'updated_at': '2026-11-22T00:00:00Z',
          },
      ],
    };

    Map<String, Object?> session() {
      String part(Map<String, Object?> data) =>
          base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
      final expiresAt =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      return {
        'access_token': [
          part({'alg': 'HS256', 'typ': 'JWT'}),
          part({'sub': 'user-1', 'exp': expiresAt, 'role': 'authenticated'}),
          'signature',
        ].join('.'),
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': expiresAt,
        'refresh_token': 'refresh-token',
        'user': user(),
      };
    }

    test('email and password', () async {
      final service = AuthService(open((_) async => json(session())).auth);
      final users = <SessionUser?>[];
      final subscription = service.userChanges.listen(users.add);
      addTearDown(subscription.cancel);
      await service.signIn(email: 'ana@example.com', password: 'secret123');
      await Future<void>.delayed(Duration.zero);

      expect(requests.single.url.path, '/auth/v1/token');
      expect(requests.single.url.queryParameters['grant_type'], 'password');
      expect(
        users.last,
        const SessionUser(id: 'user-1', email: 'ana@example.com'),
      );
    });

    test('sign-up sends the names but never a role', () async {
      final service = AuthService(open((_) async => json(user())).auth);
      final mustConfirm = await service.signUp(
        firstName: 'Ana',
        lastName: 'Cruz',
        email: 'ana@example.com',
        password: 'secret123',
      );
      expect(mustConfirm, isTrue);
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['data'], {'firstname': 'Ana', 'lastname': 'Cruz'});
      expect(
        requests.single.url.queryParameters['redirect_to'],
        SupabaseConfig.mobileRedirectUrl,
      );
    });

    test('sign-up spots an email that already has an account', () async {
      final service = AuthService(
        open((_) async => json(user(hasIdentity: false))).auth,
      );
      await expectLater(
        service.signUp(
          firstName: 'Ana',
          lastName: 'Cruz',
          email: 'ana@example.com',
          password: 'secret123',
        ),
        fails(AppErrorKind.unknown, contains('already has an account')),
      );
    });

    test('sign-out without internet still signs out on this device', () async {
      final service = AuthService(
        open((request) async {
          if (request.url.path.endsWith('/logout')) {
            throw http.ClientException('offline');
          }
          return json(session());
        }).auth,
      );
      await service.signIn(email: 'ana@example.com', password: 'secret123');
      await service.signOut();
      expect(client.auth.currentSession, isNull);
    });

    test('Google is asked to come back to the app', () async {
      open((_) async => json({}));
      final response = await client.auth.getOAuthSignInUrl(
        provider: OAuthProvider.google,
        redirectTo: authRedirectUrl,
        queryParams: const {'prompt': 'select_account'},
      );
      final url = Uri.parse(response.url);
      expect(url.path, '/auth/v1/authorize');
      expect(url.queryParameters['provider'], 'google');
      expect(
        url.queryParameters['redirect_to'],
        'io.supabase.shopping://login-callback/',
      );
      expect(url.queryParameters['code_challenge_method'], 's256');
      expect(url.queryParameters['prompt'], 'select_account');
    });

    test('Google is offered on Android and iOS, not on desktop', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      for (final (platform, available) in [
        (TargetPlatform.android, true),
        (TargetPlatform.iOS, true),
        (TargetPlatform.windows, false),
        (TargetPlatform.macOS, false),
        (TargetPlatform.linux, false),
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(googleRedirectSupported, available, reason: '$platform');
      }
    });

    test('errors are readable', () {
      String message(String code, [String text = 'x']) =>
          authError(AuthException(text, code: code)).message;
      expect(message('invalid_credentials'), 'Wrong email or password.');
      expect(message('email_not_confirmed'), contains('Confirm your email'));
      expect(message('user_already_exists'), contains('already has'));
      expect(
        message(
          'validation_failed',
          'Unsupported provider: provider is not enabled',
        ),
        contains('Google sign-in is not turned on'),
      );
      expect(
        message('unexpected_failure', 'Database error saving new user'),
        contains('final_exam.sql'),
      );
      expect(
        authError(AuthRetryableFetchException()).kind,
        AppErrorKind.network,
      );
    });
  });

  group('database errors have the right kind', () {
    Future<void> load(int status, Map<String, Object?> body) => CategoryService(
      open((_) async => json(body, status: status)),
    ).fetchAll();

    test('permission, setup, session, and API key', () async {
      await expectLater(
        load(403, {'code': '42501', 'message': 'permission denied for table'}),
        fails(AppErrorKind.permissionDenied),
      );
      for (final code in [
        '42P01',
        '42703',
        'PGRST200',
        'PGRST202',
        'PGRST205',
      ]) {
        await expectLater(
          load(404, {'code': code, 'message': 'missing'}),
          fails(AppErrorKind.unknown, contains('final_exam.sql')),
          reason: code,
        );
      }
      await expectLater(
        load(401, {'code': 'PGRST303', 'message': 'JWT expired'}),
        fails(AppErrorKind.permissionDenied, contains('session')),
      );
      await expectLater(
        load(401, {'message': 'Invalid API key'}),
        fails(AppErrorKind.unknown, contains('SUPABASE_PUBLISHABLE_KEY')),
      );
    });

    test('duplicate names', () async {
      final service = CategoryService(
        open(
          (_) async => json({'code': '23505', 'message': 'dup'}, status: 409),
        ),
      );
      await expectLater(
        service.add('Audio'),
        fails(AppErrorKind.rejected, 'That name is already in use.'),
      );
    });
  });

  group('form checks', () {
    test('price: a number of zero or more', () {
      for (final good in ['0', '0.5', '49.99', ' 12 ', '99999999.99']) {
        expect(Validators.price(good), isNull, reason: good);
      }
      for (final bad in [
        '',
        'abc',
        '-1',
        '1.234',
        'NaN',
        '1e5',
        '1,000',
        '100000000',
      ]) {
        expect(Validators.price(bad), isNotNull, reason: bad);
      }
      expect(Validators.price('-1'), 'The price must be 0 or more');
    });

    test('stock: a whole number of zero or more', () {
      for (final good in ['0', '7', ' 12 ']) {
        expect(Validators.stock(good), isNull, reason: good);
      }
      for (final bad in [
        '',
        'abc',
        '-1',
        '1.5',
        '1e3',
        '99999999999999999999',
      ]) {
        expect(Validators.stock(bad), isNotNull, reason: bad);
      }
      expect(Validators.stock('-1'), 'The stock must be 0 or more');
      expect(Validators.stock('1.5'), contains('whole number'));
    });

    test('email and password', () {
      expect(Validators.email('ana@example.com'), isNull);
      expect(Validators.email('ana'), isNotNull);
      expect(Validators.newPassword('12345'), isNotNull);
      expect(Validators.newPassword('123456'), isNull);
    });
  });
}
