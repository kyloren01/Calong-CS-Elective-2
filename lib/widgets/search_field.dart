import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_providers.dart';

/// Searches products by name. It waits until typing pauses, so every letter
/// doesn't run its own query.
class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key});

  static const pause = Duration(milliseconds: 400);

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  late final _controller = TextEditingController(
    text: ref.read(catalogFiltersProvider).search,
  );
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _timer?.cancel();
    _timer = Timer(SearchField.pause, () => _search(text));
    setState(() {}); // Shows or hides the clear button.
  }

  void _search(String text) {
    _timer?.cancel();
    final filters = ref.read(catalogFiltersProvider);
    if (text.trim() == filters.search) return;
    ref.read(catalogFiltersProvider.notifier).search(text);
  }

  @override
  Widget build(BuildContext context) {
    // "Clear filters" empties the box too.
    ref.listen(catalogFiltersProvider.select((filters) => filters.search), (
      _,
      search,
    ) {
      if (_controller.text.trim() == search) return;
      _timer?.cancel();
      setState(() => _controller.text = search);
    });

    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: _changed,
      onSubmitted: _search,
      decoration: InputDecoration(
        hintText: 'Search products',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _controller.clear();
                  _search('');
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}
