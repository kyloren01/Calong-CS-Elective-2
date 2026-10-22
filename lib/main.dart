import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'screens/pokedex_list_screen.dart';
import 'services/pokemon_service.dart';
import 'state/pokedex_cubit.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key, this.service});

  final PokemonService? service;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PokedexCubit(service: service ?? PokemonService())..fetch(),
      child: MaterialApp(
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
        home: const PokedexListScreen(),
      ),
    );
  }
}
