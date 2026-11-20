import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_ui/data/product_repository.dart';
import 'package:my_first_flutter_ui/data/supabase_product_repository.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// These tests run the real Supabase client, but answer its HTTP requests
/// here, so they check the exact query the app sends to Supabase.
void main() {
  late List<http.Request> requests;
  late SupabaseClient client;

  SupabaseProductRepository repositoryWith(
    Future<http.Response> Function(http.Request request) answer,
  ) {
    requests = [];
    client = SupabaseClient(
      'https://demo.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await answer(request);
        // Real clients attach the request to the response, and the Supabase
        // client reads it (MockClient does not do this on its own).
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          reasonPhrase: response.reasonPhrase,
          request: request,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    return SupabaseProductRepository(client);
  }

  tearDown(() => client.dispose());

  http.Response json(
    Object body, {
    int status = 200,
    Map<String, String> headers = const {},
  }) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json', ...headers},
  );

  const draft = ProductDraft(
    name: 'Desk Mat',
    description: 'Soft felt.',
    category: 'Home',
    price: 19.5,
  );

  test('fetchProducts sends the price range, category, order, and page', () async {
    final repository = repositoryWith(
      (_) async => json(
        [
          {'id': 20, 'name': 'Chef Knife', 'description': 'Sharp.', 'category': 'Kitchen', 'price': 64},
          {'id': 5, 'name': 'Tea Tin', 'description': 'Airtight.', 'category': 'Kitchen', 'price': 74.5},
        ],
        status: 206,
        headers: {'content-range': '6-7/8'},
      ),
    );

    final page = await repository.fetchProducts(
      page: 2,
      pageSize: 6,
      price: const PriceRange(40, 130),
      category: 'Kitchen',
    );

    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url.path, '/rest/v1/products');
    expect(request.url.queryParametersAll, {
      'select': ['*'],
      'price': ['gte.40.0', 'lte.130.0'],
      'category': ['eq.Kitchen'],
      'order': ['price.asc.nullslast,id.asc.nullslast'],
      'offset': ['6'],
      'limit': ['6'],
    });
    expect(request.headers['Prefer'], contains('count=exact'));
    expect(request.headers['apikey'], 'test-key');
    expect(page.totalCount, 8);
    expect(page.products.map((p) => p.name), ['Chef Knife', 'Tea Tin']);
    expect(page.products.map((p) => p.price), [64.0, 74.5]);
  });

  test('fetchProducts sends no filters for the full range and All', () async {
    final repository = repositoryWith(
      (_) async => json([], headers: {'content-range': '*/0'}),
    );

    final page = await repository.fetchProducts(page: 1, pageSize: 6);

    expect(
      requests.single.url.queryParameters.keys,
      unorderedEquals(['select', 'order', 'offset', 'limit']),
    );
    expect(page.products, isEmpty);
    expect(page.totalCount, 0);
  });

  test('a page past the end (HTTP 416) falls back to a count query', () async {
    final repository = repositoryWith((request) async {
      if (request.method == 'HEAD') {
        return http.Response('', 200, headers: {'content-range': '0-11/12'});
      }
      return json({
        'code': 'PGRST103',
        'message': 'Requested range not satisfiable',
        'details': 'An offset of 18 was requested, but there are only 12 rows.',
        'hint': null,
      }, status: 416);
    });

    final page = await repository.fetchProducts(
      page: 4,
      pageSize: 6,
      price: const PriceRange(40, 130),
    );

    expect(page.products, isEmpty);
    expect(page.totalCount, 12);
    expect(requests.map((r) => r.method), ['GET', 'HEAD']);
    expect(requests.last.url.queryParametersAll['price'], [
      'gte.40.0',
      'lte.130.0',
    ]);
  });

  test('fetchPriceBounds reads the cheapest and the priciest price', () async {
    final repository = repositoryWith((request) async {
      expect(request.url.queryParameters['select'], 'price');
      expect(request.url.queryParameters['limit'], '1');
      final cheapestFirst = request.url.queryParameters['order']!.startsWith(
        'price.asc',
      );
      return json([
        {'price': cheapestFirst ? 18 : 249.5},
      ]);
    });

    expect(await repository.fetchPriceBounds(), const PriceRange(18, 249.5));
    expect(requests, hasLength(2));
  });

  test('fetchPriceBounds is null when the table is empty', () async {
    final repository = repositoryWith((_) async => json([]));
    expect(await repository.fetchPriceBounds(), isNull);
  });

  test('fetchCategories lists each category once, A to Z', () async {
    final repository = repositoryWith((request) async {
      expect(request.url.queryParameters['order'], 'category.asc.nullslast');
      return json([
        {'category': 'Audio'},
        {'category': 'Audio'},
        {'category': 'Bags'},
      ]);
    });

    expect(await repository.fetchCategories(), ['Audio', 'Bags']);
  });

  test('createProduct inserts the draft', () async {
    final repository = repositoryWith((_) async => http.Response('', 201));

    await repository.createProduct(draft);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, '/rest/v1/products');
    expect(jsonDecode(request.body), {
      'name': 'Desk Mat',
      'description': 'Soft felt.',
      'category': 'Home',
      'price': 19.5,
    });
  });

  test('updateProduct and deleteProduct target one id', () async {
    final repository = repositoryWith(
      (_) async => json([
        {'id': 7},
      ]),
    );

    await repository.updateProduct(7, draft);
    await repository.deleteProduct(7);

    expect(requests.map((r) => r.method), ['PATCH', 'DELETE']);
    for (final request in requests) {
      expect(request.url.queryParameters, {'id': 'eq.7', 'select': 'id'});
    }
    expect(jsonDecode(requests.first.body), draft.toJson());
  });

  test('update and delete fail when no row changed, as with RLS', () async {
    final repository = repositoryWith((_) async => json([]));

    await expectLater(
      repository.updateProduct(7, draft),
      throwsA(isA<ProductRepositoryException>()),
    );
    await expectLater(
      repository.deleteProduct(7),
      throwsA(isA<ProductRepositoryException>()),
    );
  });

  group('errors become messages a person can act on', () {
    Future<String> messageFor(http.Response response) async {
      final repository = repositoryWith((_) async => response);
      try {
        await repository.createProduct(draft);
      } on ProductRepositoryException catch (error) {
        return error.message;
      }
      throw StateError('createProduct should have failed');
    }

    test('blocked by RLS', () async {
      final message = await messageFor(
        json({
          'code': '42501',
          'message': 'new row violates row-level security policy for table "products"',
        }, status: 403),
      );
      expect(message, contains('RLS policies'));
    });

    test('missing table', () async {
      final message = await messageFor(
        json({
          'code': 'PGRST205',
          'message': "Could not find the table 'public.products' in the schema cache",
        }, status: 404),
      );
      expect(message, contains('supabase/schema.sql'));
    });

    test('wrong API key', () async {
      final message = await messageFor(
        json({'message': 'Invalid API key'}, status: 401),
      );
      expect(message, contains('SUPABASE_PUBLISHABLE_KEY'));
    });

    test('no internet', () async {
      final repository = repositoryWith(
        (_) async => throw http.ClientException('Failed host lookup'),
      );
      // A write, because Supabase retries failed reads for several seconds.
      await expectLater(
        repository.createProduct(draft),
        throwsA(
          isA<ProductRepositoryException>().having(
            (error) => error.message,
            'message',
            contains('Could not reach Supabase'),
          ),
        ),
      );
    });
  });
}
