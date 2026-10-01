import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import 'pokemon_card.dart';

class PokemonGrid extends StatelessWidget {
  const PokemonGrid({super.key, required this.pokemon});

  final List<Pokemon> pokemon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 700
            ? 4
            : constraints.maxWidth >= 450
            ? 3
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          itemCount: pokemon.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            return PokemonCard(pokemon: pokemon[index], index: index);
          },
        );
      },
    );
  }
}
