import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';

/// The shop's mark: an orange circle with a shopping bag.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.orange, AppColors.burntOrange],
      ),
    ),
    child: Icon(
      Icons.shopping_bag_rounded,
      color: Colors.white,
      size: size * 0.55,
    ),
  );
}

/// The mark and name, for app bars.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.suffix});

  /// Such as "Admin".
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(size: 32),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            AppConfig.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (suffix case final suffix?) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              suffix,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Google's four-colour G, drawn to avoid shipping an image file.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _GoogleLogoPainter());
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.21;
    final ring = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Angles in radians, clockwise from 3 o'clock.
    void arc(double start, double sweep, Color color) =>
        canvas.drawArc(ring, start, sweep, false, paint..color = color);
    arc(3.55, 1.95, _red);
    arc(2.55, 1.02, _yellow);
    arc(0.82, 1.75, _green);
    arc(-0.02, 0.86, _blue);

    // The bar from the centre to the right edge.
    canvas.drawRect(
      Rect.fromLTRB(
        size.width * 0.5,
        size.height * 0.5 - stroke / 2,
        size.width,
        size.height * 0.5 + stroke / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
