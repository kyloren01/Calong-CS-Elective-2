import 'package:flutter/material.dart';

class MyBox extends StatelessWidget {
  const MyBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD8DDE5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC5CCD6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Spacer(),
          _WireLine(width: 46, height: 12, color: Color(0xFFB3BBC7)),
          const SizedBox(height: 10),
          _WireLine(width: 74, height: 9, color: Color(0xFFBEC5CF)),
          const SizedBox(height: 6),
          _WireLine(width: 54, height: 8, color: Color(0xFFBEC5CF)),
        ],
      ),
    );
  }
}

class _WireLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const _WireLine({required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      );
}
