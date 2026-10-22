import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonService {
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, Pokemon> _detailCache = {};

  Future<Map<String, dynamic>> _getJson(Uri url) async {
    final response = await _client
        .get(url)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw const PokemonServiceException(
        'PokéAPI is unavailable. Please try again shortly.',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Pokemon>> fetchPokemon() async {
    try {
      // Keep the original project's endpoint and its first 30 Pokémon.
      final data = await _getJson(
        Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=30'),
      );
      final entries = (data['results'] as List)
          .map((entry) => Pokemon.fromJson(entry as Map<String, dynamic>))
          .toList();
      final pokemon = <Pokemon>[];

      // The list endpoint has no types. Read actual types from the detail
      // endpoints in small batches, and reuse cached details on refresh.
      for (var start = 0; start < entries.length; start += 6) {
        pokemon.addAll(
          await Future.wait(
            entries.skip(start).take(6).map((entry) async {
              final cached = _detailCache[entry.apiUrl];
              if (cached != null) return cached;
              final detail = Pokemon.fromDetailJson(
                await _getJson(Uri.parse(entry.apiUrl)),
              );
              _detailCache[entry.apiUrl] = detail;
              return detail;
            }),
          ),
        );
      }
      return pokemon;
    } on PokemonServiceException {
      rethrow;
    } on TimeoutException {
      throw const PokemonServiceException(
        'The request timed out. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const PokemonServiceException(
        'Could not reach PokéAPI. Check your internet connection and try again.',
      );
    } catch (_) {
      throw const PokemonServiceException(
        'PokéAPI returned unexpected data. Please try again.',
      );
    }
  }

  void dispose() => _client.close();
}

class PokemonServiceException implements Exception {
  const PokemonServiceException(this.message);

  final String message;
}
