import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../state/pokedex_cubit.dart';
import '../state/pokedex_state.dart';
import '../widgets/favorites_panel.dart';
import '../widgets/pokemon_grid.dart';

class PokedexListScreen extends StatelessWidget {
  const PokedexListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PokedexCubit, PokedexState>(
      builder: (context, state) {
        final cubit = context.read<PokedexCubit>();
        final loading = state.status == PokedexStatus.loading;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            titleSpacing: 20,
            title: const Text(
              'Pokédex',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh Pokémon',
                onPressed: loading ? null : cubit.fetch,
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                FavoritesPanel(state: state),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(state.selectedType),
                          initialValue: state.selectedType ?? 'all',
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Pokémon type',
                            prefixIcon: Icon(Icons.filter_alt_outlined),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('All types'),
                            ),
                            for (final type in state.availableTypes)
                              DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type[0].toUpperCase() + type.substring(1),
                                ),
                              ),
                          ],
                          onChanged: (type) =>
                              cubit.selectType(type == 'all' ? null : type),
                        ),
                      ),
                      if (state.selectedType != null)
                        IconButton(
                          tooltip: 'Clear type filter',
                          onPressed: () => cubit.selectType(null),
                          icon: const Icon(Icons.filter_alt_off_outlined),
                        ),
                    ],
                  ),
                ),
                Expanded(child: _buildContent(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, PokedexState state) {
    final cubit = context.read<PokedexCubit>();
    switch (state.status) {
      case PokedexStatus.initial:
      case PokedexStatus.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Pokémon and their types…'),
            ],
          ),
        );
      case PokedexStatus.failure:
        return _Message(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load Pokémon',
          message: state.errorMessage ?? 'Please try again.',
          action: FilledButton.icon(
            onPressed: cubit.fetch,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        );
      case PokedexStatus.success:
        if (state.pokemon.isEmpty) {
          return _Message(
            icon: Icons.catching_pokemon,
            title: 'No Pokémon found',
            message: 'The API returned an empty list.',
            action: TextButton(
              onPressed: cubit.fetch,
              child: const Text('Try again'),
            ),
          );
        }
        if (state.visiblePokemon.isEmpty) {
          return _Message(
            icon: Icons.filter_alt_off_outlined,
            title: 'No matching Pokémon',
            message: 'Try another type or clear the filter.',
            action: TextButton(
              onPressed: () => cubit.selectType(null),
              child: const Text('Clear filter'),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                '${state.visiblePokemon.length} of ${state.pokemon.length} Pokémon',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.fetch,
                child: PokemonGrid(pokemon: state.visiblePokemon),
              ),
            ),
          ],
        );
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          action,
        ],
      ),
    ),
  );
}
