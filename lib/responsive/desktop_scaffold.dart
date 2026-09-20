import 'package:flutter/material.dart';
import '../widgets/my_box.dart';
import '../widgets/my_drawer.dart';
import '../widgets/my_tile.dart';
import '../widgets/right_panel.dart';

class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('responsive wireframe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      body: Row(children: [
        const SizedBox(width: 240, child: MyDrawer()),
        Expanded(
          flex: 2,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 24),
            children: [
              Container(height: 34, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: const Color(0xFFE0E4EA), borderRadius: BorderRadius.circular(10))),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 1),
                itemBuilder: (context, index) => const MyBox(),
              ),
              const SizedBox(height: 6),
              for (int i = 0; i < 5; i++) const MyTile(),
            ],
          ),
        ),
        const Expanded(flex: 1, child: RightPanel()),
      ]),
    );
  }
}
