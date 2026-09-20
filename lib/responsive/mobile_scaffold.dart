import 'package:flutter/material.dart';
import '../widgets/my_box.dart';
import '../widgets/my_drawer.dart';
import '../widgets/my_tile.dart';

class MobileScaffold extends StatelessWidget {
  const MobileScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('responsive wireframe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      drawer: const MyDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(height: 32, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: const Color(0xFFE0E4EA), borderRadius: BorderRadius.circular(9))),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: .95),
            itemBuilder: (context, index) => const MyBox(),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < 4; i++) const MyTile(),
        ],
      ),
    );
  }
}
