import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// App entry widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Instagram UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE1306C),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        dividerColor: const Color(0xFFEAEAEA),
      ),
      home: const InstagramMockPage(),
    );
  }
}

// Main mock screen layout.
class InstagramMockPage extends StatelessWidget {
  const InstagramMockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 600
                ? 600.0
                : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    const _TopBar(),
                    const Divider(height: 1, color: Color(0xFFE5E5E5)),
                    const _StoryRow(),
                    const Divider(height: 1, color: Color(0xFFEFEFEF)),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: const [_PostCard()],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E5E5)),
                    const _BottomNavBar(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Top header bar.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    // Top app header.
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text(
              'Instagram',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                letterSpacing: -1.1,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(Icons.favorite_border_rounded, size: 25),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints.tightFor(width: 36, height: 36),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 24),
                ),
                Positioned(
                  right: 3,
                  top: 1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF04438),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Story preview section.
class _StoryRow extends StatelessWidget {
  const _StoryRow();

  @override
  Widget build(BuildContext context) {
    // Story preview row.
    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF9CE34),
                    Color(0xFFEE2A7B),
                    Color(0xFF6228D7),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Container(
                margin: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Text(
              'username',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF262626),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 40),
              icon: const Icon(Icons.more_vert, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// Single post content card.
class _PostCard extends StatelessWidget {
  const _PostCard();

  @override
  Widget build(BuildContext context) {
    // Static post content.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF654EA3),
                  Color(0xFFB83A9B),
                  Color(0xFFE73488),
                  Color(0xFFF64E5D),
                  Color(0xFFFFB347),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 2),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFE53935), size: 22),
              const SizedBox(width: 10),
              const Icon(Icons.mode_comment_outlined, size: 21),
              const SizedBox(width: 10),
              const Icon(Icons.send_outlined, size: 21),
              const Spacer(),
              const Icon(Icons.bookmark_border, size: 22),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '10547 Likes',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '@username  ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: 'Lorem ipsum dolor sit amet, consectetur',
                  style: TextStyle(color: Colors.black87, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '#lorem  #ipsum  #dolor  #sit  #amet  #consectetur',
            style: TextStyle(color: Color(0xFF4F7CAC), fontSize: 9.5),
          ),
        ),
        const SizedBox(height: 7),
      ],
    );
  }
}

// Bottom navigation row.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _InstagramNavButton(
              icon: _InstagramNavIcon.home,
              label: 'Home',
            ),
            _InstagramNavButton(
              icon: _InstagramNavIcon.search,
              label: 'Search',
            ),
            _InstagramNavButton(
              icon: _InstagramNavIcon.create,
              label: 'Create',
            ),
            _InstagramNavButton(
              icon: _InstagramNavIcon.reels,
              label: 'Reels',
            ),
            _InstagramNavButton(
              icon: _InstagramNavIcon.profile,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

enum _InstagramNavIcon { home, search, create, reels, profile }

class _InstagramNavButton extends StatelessWidget {
  const _InstagramNavButton({required this.icon, required this.label});

  final _InstagramNavIcon icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(
          painter: _InstagramNavIconPainter(icon),
        ),
      ),
    );
  }
}

class _InstagramNavIconPainter extends CustomPainter {
  _InstagramNavIconPainter(this.icon);

  final _InstagramNavIcon icon;

  Paint get _stroke => Paint()
    ..color = Colors.black
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.15
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    switch (icon) {
      case _InstagramNavIcon.home:
        // The reference uses a solid, softly shaped house rather than the
        // sharper Material home glyph.
        path
          ..moveTo(3.5, 13.1)
          ..lineTo(14, 4.2)
          ..lineTo(24.5, 13.1)
          ..lineTo(24.5, 24)
          ..lineTo(16.7, 24)
          ..lineTo(16.7, 16.5)
          ..lineTo(11.3, 16.5)
          ..lineTo(11.3, 24)
          ..lineTo(3.5, 24)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.black);
      case _InstagramNavIcon.search:
        canvas.drawCircle(const Offset(12, 12), 8.1, _stroke);
        canvas.drawLine(const Offset(18, 18), const Offset(24, 24), _stroke);
      case _InstagramNavIcon.create:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 4, 20, 20),
            const Radius.circular(5.2),
          ),
          _stroke,
        );
        canvas.drawLine(const Offset(10, 14), const Offset(18, 14), _stroke);
        canvas.drawLine(const Offset(14, 10), const Offset(14, 18), _stroke);
      case _InstagramNavIcon.reels:
        final reelsRect = RRect.fromRectAndRadius(
          const Rect.fromLTWH(4, 3.5, 20, 21),
          const Radius.circular(5.2),
        );
        canvas.drawRRect(reelsRect, _stroke);
        canvas.drawLine(const Offset(4.8, 9.2), const Offset(23.2, 9.2), _stroke);
        canvas.drawLine(const Offset(9, 3.9), const Offset(13, 9.1), _stroke);
        canvas.drawLine(const Offset(16, 3.9), const Offset(20, 9.1), _stroke);
        path
          ..moveTo(11.2, 13)
          ..lineTo(11.2, 20)
          ..lineTo(17.5, 16.5)
          ..close();
        canvas.drawPath(path, Paint()..color = Colors.black);
      case _InstagramNavIcon.profile:
        canvas.drawCircle(const Offset(14, 8.7), 4.1, _stroke);
        path
          ..moveTo(4.1, 23.8)
          ..cubicTo(4.8, 18.8, 8.2, 16.3, 14, 16.3)
          ..cubicTo(19.8, 16.3, 23.2, 18.8, 23.9, 23.8)
          ..close();
        canvas.drawPath(path, _stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _InstagramNavIconPainter oldDelegate) {
    return oldDelegate.icon != icon;
  }
}
