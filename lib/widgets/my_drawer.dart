import 'package:flutter/material.dart';

// Navigation drawer and sidebar widget
class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey[200],
      elevation: 0,
      child: Column(
        children: [
          // Header with heart logo
          const DrawerHeader(
            child: Icon(
              Icons.favorite,
              size: 48,
              color: Colors.black,
            ),
          ),
          // Menu items
          ListTile(
            leading: const Icon(Icons.home, color: Colors.black),
            title: const Text(
              'D A S H B O A R D',
              style: TextStyle(letterSpacing: 1.5, fontSize: 13),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.black),
            title: const Text(
              'S E T T I N G S',
              style: TextStyle(letterSpacing: 1.5, fontSize: 13),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Colors.black),
            title: const Text(
              'A B O U T',
              style: TextStyle(letterSpacing: 1.5, fontSize: 13),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black),
            title: const Text(
              'L O G O U T',
              style: TextStyle(letterSpacing: 1.5, fontSize: 13),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
