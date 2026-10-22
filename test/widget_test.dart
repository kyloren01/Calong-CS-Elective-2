import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/models/pokemon.dart';
import 'package:my_first_flutter_ui/services/pokemon_service.dart';
import 'package:my_first_flutter_ui/widgets/pokemon_card.dart';
import 'package:my_first_flutter_ui/widgets/pokemon_grid.dart';
import 'package:my_first_flutter_ui/widgets/favorites_panel.dart';

import 'support/fake_pokemon_service.dart';

void main() {
  testWidgets(
    'nicknames, favorites, filtering, and refresh stay synchronized',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = FakePokemonService(load: () async => samplePokemon);
      final gridCards = find.descendant(
        of: find.byType(PokemonGrid),
        matching: find.byType(PokemonCard),
      );
      await tester.pumpWidget(PokedexApp(service: service));
      await tester.pumpAndSettle();
      expect(gridCards, findsNWidgets(2));
      expect(find.text('#001'), findsOneWidget);

      await tester.tap(find.text('Favorites (0)'));
      await tester.pumpAndSettle();
      expect(
        find.text('No favorites yet. Tap a heart to add a Pokémon.'),
        findsOneWidget,
      );
      expect(gridCards, findsNWidgets(2));
      await tester.tap(find.byTooltip('Add Bulbasaur to favorites'));
      await tester.pumpAndSettle();
      expect(find.text('Favorites (1)'), findsOneWidget);
      final favoriteCard = find.descendant(
        of: find.byType(FavoritesPanel),
        matching: find.byType(PokemonCard),
      );
      expect(tester.widget<PokemonCard>(favoriteCard).compact, isTrue);
      expect(
        find.descendant(of: favoriteCard, matching: find.byType(Image)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: favoriteCard,
          matching: find.text('Grass · Poison'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(favoriteCard).height,
        lessThan(tester.getSize(gridCards.first).height),
      );
      expect(
        tester.getSize(favoriteCard).width,
        lessThan(tester.getSize(gridCards.first).width),
      );

      await tester.tap(find.text('Nickname').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Leafy');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Leafy'), findsNWidgets(2));
      expect(find.text('Bulbasaur'), findsNWidgets(2));

      await tester.tap(find.text('Edit nickname').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Sprout');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Sprout'), findsNWidgets(2));

      await tester.tap(find.text('All types'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fire').last);
      await tester.pumpAndSettle();
      expect(gridCards, findsOneWidget);
      expect(find.text('Charmander'), findsOneWidget);
      expect(find.text('Sprout'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear type filter'));
      await tester.pumpAndSettle();
      expect(gridCards, findsNWidgets(2));

      await tester.tap(find.byTooltip('Refresh Pokémon'));
      await tester.pumpAndSettle();
      expect(service.calls, 2);
      expect(find.text('Sprout'), findsNWidgets(2));

      await tester.tap(find.text('Edit nickname').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove nickname'));
      await tester.pumpAndSettle();
      expect(find.text('Sprout'), findsNothing);
      await tester.tap(find.byTooltip('Remove Bulbasaur from favorites').first);
      await tester.pumpAndSettle();
      expect(find.text('Favorites (0)'), findsOneWidget);
      expect(gridCards, findsNWidgets(2));
      expect(
        find.text('No favorites yet. Tap a heart to add a Pokémon.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Favorites (0)'));
      await tester.pumpAndSettle();
      expect(gridCards, findsNWidgets(2));
      expect(
        find.text('No favorites yet. Tap a heart to add a Pokémon.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows loading then a meaningful error and retries', (
    tester,
  ) async {
    final pending = Completer<List<Pokemon>>();
    final service = FakePokemonService(load: () => pending.future);
    await tester.pumpWidget(PokedexApp(service: service));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(
      const PokemonServiceException('Check your internet connection.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Check your internet connection.'), findsOneWidget);
    service.load = () async => samplePokemon;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(PokemonCard), findsNWidgets(2));
    expect(service.calls, 2);
  });

  testWidgets('empty API results offer retry', (tester) async {
    await tester.pumpWidget(
      PokedexApp(service: FakePokemonService(load: () async => [])),
    );
    await tester.pumpAndSettle();
    expect(find.text('No Pokémon found'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
