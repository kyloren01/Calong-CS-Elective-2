import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/pokemon.dart';
import 'package:my_first_flutter_ui/services/pokemon_service.dart';
import 'package:my_first_flutter_ui/state/pokedex_cubit.dart';
import 'package:my_first_flutter_ui/state/pokedex_state.dart';

import 'support/fake_pokemon_service.dart';

void main() {
  test('refresh preserves edits, favorites, and the active filter', () async {
    final service = FakePokemonService(load: () async => samplePokemon);
    final cubit = PokedexCubit(service: service);
    addTearDown(cubit.close);
    await cubit.fetch();
    cubit.saveNickname(bulbasaur, '  Leafy  ');
    cubit.toggleFavorite(bulbasaur);
    cubit.toggleFavoritesPanel();
    cubit.selectType('fire');
    expect(cubit.state.visiblePokemon, [charmander]);
    expect(cubit.state.favorites, [bulbasaur]);

    await cubit.fetch();
    expect(service.calls, 2);
    expect(cubit.state.nicknameFor(bulbasaur), 'Leafy');
    expect(cubit.state.favoritesExpanded, isTrue);
    expect(cubit.state.selectedType, 'fire');
    expect(cubit.state.favorites, [bulbasaur]);

    cubit.selectType('poison');
    expect(cubit.state.visiblePokemon, [bulbasaur]);
    cubit.selectType(null);
    expect(cubit.state.visiblePokemon, samplePokemon);
    cubit.removeNickname(bulbasaur);
    cubit.toggleFavorite(bulbasaur);
    expect(cubit.state.nicknameFor(bulbasaur), isNull);
    expect(cubit.state.favorites, isEmpty);
  });

  test('loading is immediate and repeated fetches do not overlap', () async {
    final pending = Completer<List<Pokemon>>();
    final service = FakePokemonService(load: () => pending.future);
    final cubit = PokedexCubit(service: service);
    addTearDown(cubit.close);
    final request = cubit.fetch();
    expect(cubit.state.status, PokedexStatus.loading);
    await cubit.fetch();
    expect(service.calls, 1);
    pending.complete(samplePokemon);
    await request;
    expect(cubit.state.status, PokedexStatus.success);
  });

  test(
    'failure can be retried through fetch without losing favorites',
    () async {
      final service = FakePokemonService(load: () async => samplePokemon);
      final cubit = PokedexCubit(service: service);
      addTearDown(cubit.close);
      await cubit.fetch();
      cubit.toggleFavorite(bulbasaur);
      service.load = () async => throw const PokemonServiceException('Offline');
      await cubit.fetch();
      expect(cubit.state.status, PokedexStatus.failure);
      expect(cubit.state.errorMessage, 'Offline');
      expect(cubit.state.favorites, [bulbasaur]);
      service.load = () async => samplePokemon;
      await cubit.fetch();
      expect(cubit.state.status, PokedexStatus.success);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.favorites, [bulbasaur]);
    },
  );

  test('refresh clears a type that is no longer available', () async {
    final service = FakePokemonService(load: () async => samplePokemon);
    final cubit = PokedexCubit(service: service);
    addTearDown(cubit.close);
    await cubit.fetch();
    cubit.selectType('fire');
    service.load = () async => [bulbasaur];
    await cubit.fetch();
    expect(cubit.state.selectedType, isNull);
    expect(cubit.state.visiblePokemon, [bulbasaur]);
  });

  test(
    'closing during a request disposes resources without a late emit',
    () async {
      final pending = Completer<List<Pokemon>>();
      final service = FakePokemonService(load: () => pending.future);
      final cubit = PokedexCubit(service: service);
      final request = cubit.fetch();
      await cubit.close();
      pending.complete(samplePokemon);
      await request;
      expect(service.disposed, isTrue);
    },
  );
}
