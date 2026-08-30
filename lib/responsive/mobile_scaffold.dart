import 'package:flutter/material.dart';
import '../widgets/my_box.dart';
import '../widgets/my_drawer.dart';
import '../widgets/my_tile.dart';

// Mobile layout view for screen widths less than 600px
class MobileScaffold extends StatelessWidget {
  const MobileScaffold({super.key});

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
          // 2x2 top grid for mobile
          AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemBuilder: (context, index) {
                return const MyBox();
              },
            ),
          ),
          // Vertical list tiles
          for (int i = 0; i < 4; i++) const MyTile(),
        ],
      ),
    );
  }
}
