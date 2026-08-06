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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
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
        // Main vertical page layout.
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
  }
}

// Top header bar.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    // Top app header.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Instagram',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              letterSpacing: -0.8,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border, size: 28),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline, size: 26),
              ),
              Positioned(
                right: 7,
                top: 5,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
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
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                margin: const EdgeInsets.all(2.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'username',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
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
          aspectRatio: 1,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF6559CA),
                  Color(0xFFBC318F),
                  Color(0xFFE33F5F),
                  Color(0xFFF77737),
                  Color(0xFFFCAF45),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red, size: 26),
              const SizedBox(width: 12),
              const Icon(Icons.mode_comment_outlined, size: 25),
              const SizedBox(width: 12),
              const Icon(Icons.send_outlined, size: 24),
              const Spacer(),
              const Icon(Icons.bookmark_border, size: 25),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '10547 Likes',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '@username  ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: 'Lorem ipsum dolor sit amet, consectetur',
                  style: TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '#lorem  #ipsum  #dolor  #sit  #amet  #consectetur',
            style: TextStyle(color: Color(0xFF4F7CAC), fontSize: 12),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// Bottom navigation row.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    // Bottom navigation icons.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: const [
          Icon(Icons.home_filled, size: 28),
          Spacer(),
          Icon(Icons.search, size: 28),
          Spacer(),
          Icon(Icons.add_box_outlined, size: 28),
          Spacer(),
          Icon(Icons.video_collection_outlined, size: 28),
          Spacer(),
          Icon(Icons.person_outline, size: 28),
        ],
      ),
    );
  }
}
