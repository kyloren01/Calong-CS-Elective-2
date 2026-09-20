import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: double.infinity,
      backgroundColor: const Color(0xFFE7EAEE),
      elevation: 0,
      child: Column(
        children: [
          const SizedBox(
            height: 190,
            child: DrawerHeader(
              margin: EdgeInsets.zero,
              child: Center(child: Icon(Icons.dashboard_customize_rounded, size: 58, color: Color(0xFF293241))),
            ),
          ),
          const Divider(indent: 28, endIndent: 28, color: Color(0xFFC3CAD3)),
          const SizedBox(height: 20),
          _MenuItem(icon: Icons.grid_view_rounded, label: 'D A S H B O A R D', selected: true),
          _MenuItem(icon: Icons.tune_rounded, label: 'S E T T I N G S'),
          _MenuItem(icon: Icons.info_outline_rounded, label: 'A B O U T'),
          _MenuItem(icon: Icons.logout_rounded, label: 'L O G O U T'),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _MenuItem({required this.icon, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(color: selected ? const Color(0xFFD0D6DE) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF293241)),
        title: Text(label, style: const TextStyle(fontSize: 12, letterSpacing: 1.4, color: Color(0xFF293241))),
        onTap: () {},
      ),
    );
  }
}
