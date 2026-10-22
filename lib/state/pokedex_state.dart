import '../models/pokemon.dart';

enum PokedexStatus { initial, loading, success, failure }

class PokedexState {
  PokedexState({
    this.status = PokedexStatus.initial,
    List<Pokemon> pokemon = const [],
    Map<String, String> nicknames = const {},
    Set<String> favoriteUrls = const {},
    this.selectedType,
    this.favoritesExpanded = false,
    this.errorMessage,
  }) : pokemon = List.unmodifiable(pokemon),
       nicknames = Map.unmodifiable(nicknames),
       favoriteUrls = Set.unmodifiable(favoriteUrls);

  final PokedexStatus status;
  final List<Pokemon> pokemon;
  final Map<String, String> nicknames;
  final Set<String> favoriteUrls;
  final String? selectedType;
  final bool favoritesExpanded;
  final String? errorMessage;

  bool isFavorite(Pokemon entry) => favoriteUrls.contains(entry.apiUrl);
  String? nicknameFor(Pokemon entry) => nicknames[entry.apiUrl];

  List<Pokemon> get favorites => pokemon.where(isFavorite).toList();

  List<Pokemon> get visiblePokemon => selectedType == null
      ? pokemon
      : pokemon.where((entry) => entry.types.contains(selectedType)).toList();

  List<String> get availableTypes =>
      (pokemon.expand((entry) => entry.types).toSet().toList()..sort());

  PokedexState copyWith({
    PokedexStatus? status,
    List<Pokemon>? pokemon,
    Map<String, String>? nicknames,
    Set<String>? favoriteUrls,
    String? selectedType,
    bool clearType = false,
    bool? favoritesExpanded,
    String? errorMessage,
    bool clearError = false,
  }) => PokedexState(
    status: status ?? this.status,
    pokemon: pokemon ?? this.pokemon,
    nicknames: nicknames ?? this.nicknames,
    favoriteUrls: favoriteUrls ?? this.favoriteUrls,
    selectedType: clearType ? null : selectedType ?? this.selectedType,
    favoritesExpanded: favoritesExpanded ?? this.favoritesExpanded,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );
}
