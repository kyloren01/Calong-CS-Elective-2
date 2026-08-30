import 'package:flutter/material.dart';
import '../widgets/my_box.dart';
import '../widgets/my_drawer.dart';
import '../widgets/my_tile.dart';
import '../widgets/right_panel.dart';

// Desktop layout view for screen widths 1100px and above
class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: const Text(
          'responsivedashboard',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Row(
        children: [
          // Persistent left sidebar navigation
          const SizedBox(
            width: 240,
            child: MyDrawer(),
          ),
          // Main content area with top grid and list
          Expanded(
            flex: 2,
            child: ListView(
              children: [
                // 1x4 top grid
                AspectRatio(
                  aspectRatio: 4,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                    ),
                    itemBuilder: (context, index) {
                      return const MyBox();
                    },
                  ),
                ),
                // Vertical list tiles
                for (int i = 0; i < 5; i++) const MyTile(),
              ],
            ),
          ),
          // Right panel column
          const Expanded(
            flex: 1,
            child: RightPanel(),
          ),
        ],
      ),
    );
  }
}
