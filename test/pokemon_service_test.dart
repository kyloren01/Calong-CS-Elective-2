import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_ui/services/pokemon_service.dart';

void main() {
  test('loads actual dual types and caches details across refresh', () async {
    var listRequests = 0;
    var detailRequests = 0;
    final service = PokemonService(
      client: MockClient((request) async {
        if (request.url.queryParameters['limit'] == '30') {
          listRequests++;
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'name': 'bulbasaur',
                  'url': 'https://pokeapi.co/api/v2/pokemon/1/',
                },
              ],
            }),
            200,
          );
        }
        detailRequests++;
        return http.Response(
          jsonEncode({
            'id': 1,
            'name': 'bulbasaur',
            'types': [
              {
                'type': {'name': 'grass'},
              },
              {
                'type': {'name': 'poison'},
              },
            ],
          }),
          200,
        );
      }),
    );
    addTearDown(service.dispose);
    final pokemon = await service.fetchPokemon();
    expect(pokemon.single.types, ['grass', 'poison']);
    expect(pokemon.single.id, 1);
    await service.fetchPokemon();
    expect(listRequests, 2);
    expect(detailRequests, 1);
  });

  test('returns an empty list gracefully', () async {
    final service = PokemonService(
      client: MockClient((_) async => http.Response('{"results":[]}', 200)),
    );
    addTearDown(service.dispose);
    expect(await service.fetchPokemon(), isEmpty);
  });

  for (final status in [200, 503]) {
    test(
      'reports invalid data or HTTP $status as a meaningful error',
      () async {
        final service = PokemonService(
          client: MockClient(
            (_) async => http.Response('invalid data', status),
          ),
        );
        addTearDown(service.dispose);
        await expectLater(
          service.fetchPokemon(),
          throwsA(
            isA<PokemonServiceException>().having(
              (error) => error.message,
              'message',
              isNotEmpty,
            ),
          ),
        );
      },
    );
  }
}
