import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import 'pokedex_state.dart';

class PokedexCubit extends Cubit<PokedexState> {
  PokedexCubit({required this.service}) : super(PokedexState());

  final PokemonService service;

  // Initial load, refresh, and retry all call this same method.
  Future<void> fetch() async {
    if (isClosed || state.status == PokedexStatus.loading) return;
    emit(state.copyWith(status: PokedexStatus.loading, clearError: true));
    try {
      final pokemon = await service.fetchPokemon();
      if (isClosed) return;
      final selectedType = state.selectedType;
      emit(
        state.copyWith(
          status: PokedexStatus.success,
          pokemon: pokemon,
          clearType:
              selectedType != null &&
              !pokemon.any((entry) => entry.types.contains(selectedType)),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PokedexStatus.failure,
          errorMessage: error is PokemonServiceException
              ? error.message
              : 'Could not load Pokémon. Check your connection and try again.',
        ),
      );
    }
  }

  void saveNickname(Pokemon pokemon, String value) {
    final nickname = value.trim();
    if (nickname.isEmpty) {
      removeNickname(pokemon);
      return;
    }
    emit(
      state.copyWith(nicknames: {...state.nicknames, pokemon.apiUrl: nickname}),
    );
  }

  void removeNickname(Pokemon pokemon) {
    final nicknames = {...state.nicknames}..remove(pokemon.apiUrl);
    emit(state.copyWith(nicknames: nicknames));
  }

  void toggleFavorite(Pokemon pokemon) {
    final favorites = {...state.favoriteUrls};
    if (!favorites.add(pokemon.apiUrl)) favorites.remove(pokemon.apiUrl);
    emit(state.copyWith(favoriteUrls: favorites));
  }

  void selectType(String? type) {
    emit(state.copyWith(selectedType: type, clearType: type == null));
  }

  void toggleFavoritesPanel() {
    emit(state.copyWith(favoritesExpanded: !state.favoritesExpanded));
  }

  @override
  Future<void> close() {
    service.dispose();
    return super.close();
  }
}
