import 'package:flutter/material.dart';

import 'models/pokemon.dart';
import 'screens/pokedex_list_screen.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key, this.pokemonFuture});

  final Future<List<Pokemon>>? pokemonFuture;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pok\u00E9dex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF5350),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        useMaterial3: true,
      ),
      home: PokedexListScreen(pokemonFuture: pokemonFuture),
    );
  }
}
