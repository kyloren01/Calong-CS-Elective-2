import 'package:flutter/material.dart';
import '../widgets/my_box.dart';
import '../widgets/my_drawer.dart';
import '../widgets/my_tile.dart';

class TabletScaffold extends StatelessWidget {
  const TabletScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('responsive wireframe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      drawer: const MyDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(height: 34, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFFE0E4EA), borderRadius: BorderRadius.circular(10))),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 2.2),
            itemBuilder: (context, index) => const MyBox(),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < 5; i++) const MyTile(),
        ],
      ),
    );
  }
}
