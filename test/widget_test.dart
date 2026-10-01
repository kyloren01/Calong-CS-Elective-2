import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/models/pokemon.dart';

void main() {
  testWidgets('displays fetched Pokemon in a grid', (WidgetTester tester) async {
    const pokemon = [
      Pokemon(
        name: 'bulbasaur',
        apiUrl: 'https://pokeapi.co/api/v2/pokemon/1/',
      ),
      Pokemon(
        name: 'ivysaur',
        apiUrl: 'https://pokeapi.co/api/v2/pokemon/2/',
      ),
    ];

    await tester.pumpWidget(
      PokedexApp(pokemonFuture: Future.value(pokemon)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pok\u00E9dex'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('#001'), findsOneWidget);
  });
}
