class Pokemon {
  const Pokemon({
    required this.name,
    required this.apiUrl,
    this.types = const [],
  });

  final String name;
  final String apiUrl;
  final List<String> types;

  factory Pokemon.fromDetailJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final types = (json['types'] as List)
        .map((entry) => entry['type']['name'] as String)
        .toList();
    return Pokemon(
      name: json['name'] as String,
      apiUrl: 'https://pokeapi.co/api/v2/pokemon/$id/',
      types: List.unmodifiable(types),
    );
  }

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      name: json['name'] as String? ?? 'Unknown',
      apiUrl: json['url'] as String? ?? '',
    );
  }

  int? get id {
    final match = RegExp(r'/pokemon/(\d+)/?$').firstMatch(apiUrl);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  String? get imageUrl {
    final pokemonId = id;
    if (pokemonId == null) return null;

    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/'
        'sprites/pokemon/other/official-artwork/$pokemonId.png';
  }

  String get displayName {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }
}
