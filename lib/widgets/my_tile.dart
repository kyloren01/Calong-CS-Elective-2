import 'package:flutter/material.dart';

class MyTile extends StatelessWidget {
  const MyTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E4EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD0D6DE)),
      ),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFB9C1CC), borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 14),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Line(width: 150, height: 10),
            const SizedBox(height: 9),
            _Line(width: 95, height: 8),
          ])),
          const _Line(width: 28, height: 28, radius: 14),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _Line({required this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) => Container(width: width, height: height, decoration: BoxDecoration(color: const Color(0xFFBEC6D1), borderRadius: BorderRadius.circular(radius)));
}
