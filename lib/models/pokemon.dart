class Pokemon {
  const Pokemon({required this.name, required this.apiUrl});

  final String name;
  final String apiUrl;

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
