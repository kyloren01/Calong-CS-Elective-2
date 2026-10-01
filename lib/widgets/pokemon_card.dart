import 'package:flutter/material.dart';

import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
  const PokemonCard({super.key, required this.pokemon, required this.index});

  final Pokemon pokemon;
  final int index;

  static const _cardColors = [
    Color(0xFFFFE7E5),
    Color(0xFFE4F5E9),
    Color(0xFFE4F0FF),
    Color(0xFFFFF1D7),
    Color(0xFFF0E8FF),
  ];

  @override
  Widget build(BuildContext context) {
    final id = pokemon.id;
    final imageUrl = pokemon.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: _cardColors[index % _cardColors.length],
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 14,
            child: Text(
              id == null ? '#--' : '#${id.toString().padLeft(3, '0')}',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.35),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: imageUrl == null
                      ? const Icon(Icons.image_not_supported_outlined, size: 58)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported_outlined,
                              size: 58,
                            );
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        ),
                ),
                Text(
                  pokemon.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
