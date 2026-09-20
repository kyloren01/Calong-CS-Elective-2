import 'package:flutter/material.dart';

class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 24, 24),
      child: Column(
        children: [
          Expanded(flex: 2, child: _PanelPlaceholder()),
          const SizedBox(height: 12),
          Expanded(flex: 1, child: _PanelPlaceholder(compact: true)),
        ],
      ),
    );
  }
}

class _PanelPlaceholder extends StatelessWidget {
  final bool compact;

  const _PanelPlaceholder({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFFD8DDE5), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFC5CCD6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Bar(width: compact ? 72 : 110, height: 12),
        const SizedBox(height: 16),
        if (!compact) ...[
          _Bar(width: double.infinity, height: 92),
          const SizedBox(height: 16),
          _Bar(width: 120, height: 9),
          const SizedBox(height: 8),
          _Bar(width: 170, height: 9),
        ] else
          const Expanded(child: Center(child: Icon(Icons.more_horiz_rounded, size: 30, color: Color(0xFFB3BBC7)))),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double height;

  const _Bar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(width: width, height: height, decoration: BoxDecoration(color: const Color(0xFFB9C1CC), borderRadius: BorderRadius.circular(8)));
}
