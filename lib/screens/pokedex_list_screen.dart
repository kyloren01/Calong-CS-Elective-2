import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_grid.dart';

class PokedexListScreen extends StatefulWidget {
  const PokedexListScreen({super.key, this.pokemonFuture});

  final Future<List<Pokemon>>? pokemonFuture;

  @override
  State<PokedexListScreen> createState() => _PokedexListScreenState();
}

class _PokedexListScreenState extends State<PokedexListScreen> {
  final PokemonService _pokemonService = PokemonService();
  late Future<List<Pokemon>> _pokemonFuture;

  @override
  void initState() {
    super.initState();
    _pokemonFuture = widget.pokemonFuture ?? _pokemonService.fetchPokemon();
  }

  void _refreshPokemon() {
    setState(() {
      _pokemonFuture = _pokemonService.fetchPokemon();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 24,
        title: const Text(
          'Pok\u00E9dex',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Pok\u00E9mon',
            onPressed: _refreshPokemon,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<Pokemon>>(
        future: _pokemonFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          if (snapshot.hasError) {
            return _ErrorState(onRetry: _refreshPokemon);
          }

          final pokemon = snapshot.data ?? const <Pokemon>[];
          if (pokemon.isEmpty) {
            return const _EmptyState();
          }

          return PokemonGrid(pokemon: pokemon);
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading Pok\u00E9mon...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Could not load Pok\u00E9mon',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No Pok\u00E9mon found.',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }
}
