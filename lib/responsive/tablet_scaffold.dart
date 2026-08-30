import 'package:flutter/material.dart';
import '../widgets/my_box.dart';
import '../widgets/my_drawer.dart';
import '../widgets/my_tile.dart';

// Tablet layout view for screen widths between 600px and 1100px
class TabletScaffold extends StatelessWidget {
  const TabletScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'responsivedashboard',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      drawer: const MyDrawer(),
      body: ListView(
        children: [
          // 1x4 top grid for tablet
          AspectRatio(
            aspectRatio: 4,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}
