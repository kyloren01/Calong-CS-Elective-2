import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonService {
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Pokemon>> fetchPokemon() async {
    final url = Uri.parse(
      'https://pokeapi.co/api/v2/pokemon?limit=30',
    );
    final response = await _client.get(url);

    if (response.statusCode != 200) {
      throw Exception('Unable to load Pokemon right now.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'];

    if (results is! List) {
      throw Exception('The Pokemon data is in an unexpected format.');
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(Pokemon.fromJson)
        .toList();
  }
}
