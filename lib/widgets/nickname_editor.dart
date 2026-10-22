import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/pokemon.dart';
import '../state/pokedex_cubit.dart';

Future<void> showNicknameEditor(BuildContext context, Pokemon pokemon) {
  final cubit = context.read<PokedexCubit>();
  return showDialog<void>(
    context: context,
    builder: (_) => NicknameEditor(pokemon: pokemon, cubit: cubit),
  );
}

class NicknameEditor extends StatefulWidget {
  const NicknameEditor({super.key, required this.pokemon, required this.cubit});

  final Pokemon pokemon;
  final PokedexCubit cubit;

  @override
  State<NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends State<NicknameEditor> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.cubit.state.nicknameFor(widget.pokemon) ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.cubit.saveNickname(widget.pokemon, _controller.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Nickname for ${widget.pokemon.displayName}'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 24,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _save(),
      decoration: const InputDecoration(
        labelText: 'Nickname',
        hintText: 'Give your Pokémon a name',
        helperText: 'An empty nickname restores the original name.',
        helperMaxLines: 2,
        border: OutlineInputBorder(),
      ),
    ),
    actions: [
      if (widget.cubit.state.nicknameFor(widget.pokemon) != null)
        TextButton(
          onPressed: () {
            widget.cubit.removeNickname(widget.pokemon);
            Navigator.of(context).pop();
          },
          child: const Text('Remove nickname'),
        ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}
