import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/pokedex_cubit.dart';
import '../state/pokedex_state.dart';
import 'pokemon_card.dart';

class FavoritesPanel extends StatelessWidget {
  const FavoritesPanel({super.key, required this.state});

  final PokedexState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PokedexCubit>();
    final favorites = state.favorites;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: const Color(0xFFFFE7E5),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFBE3447),
              ),
              title: Text(
                'Favorites (${favorites.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              trailing: Icon(
                state.favoritesExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: cubit.toggleFavoritesPanel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            if (state.favoritesExpanded)
              if (favorites.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    'No favorites yet. Tap a heart to add a Pokémon.',
                  ),
                )
              else
                SizedBox(
                  height: 232,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: favorites.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 148,
                        child: PokemonCard(
                          pokemon: favorites[index],
                          index: index,
                          compact: true,
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
