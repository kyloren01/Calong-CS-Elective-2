import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/pokemon.dart';
import '../state/pokedex_cubit.dart';
import '../state/pokedex_state.dart';
import 'nickname_editor.dart';

class PokemonCard extends StatelessWidget {
  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.index,
    this.compact = false,
  });

  final Pokemon pokemon;
  final int index;
  final bool compact;

  static const _cardColors = [
    Color(0xFFE4F5E9),
    Color(0xFFFFE7E5),
    Color(0xFFE4F0FF),
    Color(0xFFFFF1D7),
    Color(0xFFF0E8FF),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PokedexCubit, PokedexState>(
      builder: (context, state) {
        final cubit = context.read<PokedexCubit>();
        final nickname = state.nicknameFor(pokemon);
        final favorite = state.isFavorite(pokemon);
        final id = pokemon.id;
        return Material(
          color: _cardColors[((id ?? index + 1) - 1) % _cardColors.length],
          borderRadius: BorderRadius.circular(compact ? 16 : 22),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 8 : 12,
              4,
              compact ? 8 : 12,
              8,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      id == null ? '#--' : '#${id.toString().padLeft(3, '0')}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 10 : 12,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      iconSize: compact ? 20 : 24,
                      visualDensity: compact
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                      key: ValueKey('favorite-${pokemon.apiUrl}'),
                      tooltip: favorite
                          ? 'Remove ${pokemon.displayName} from favorites'
                          : 'Add ${pokemon.displayName} to favorites',
                      onPressed: () => cubit.toggleFavorite(pokemon),
                      isSelected: favorite,
                      color: const Color(0xFFBE3447),
                      icon: const Icon(Icons.favorite_border_rounded),
                      selectedIcon: const Icon(Icons.favorite_rounded),
                    ),
                  ],
                ),
                Expanded(
                  child: pokemon.imageUrl == null
                      ? const Icon(Icons.image_not_supported_outlined, size: 48)
                      : Image.network(
                          pokemon.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                          ),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: SizedBox.square(
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  nickname ?? pokemon.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (nickname != null)
                  Text(
                    pokemon.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: compact ? 11 : 12),
                  ),
                Text(
                  pokemon.types
                      .map((type) => type[0].toUpperCase() + type.substring(1))
                      .join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 10 : 11),
                ),
                TextButton.icon(
                  onPressed: () => showNicknameEditor(context, pokemon),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(nickname == null ? 'Nickname' : 'Edit nickname'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: TextStyle(fontSize: compact ? 11 : 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
