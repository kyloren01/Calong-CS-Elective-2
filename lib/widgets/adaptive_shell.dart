import 'package:flutter/material.dart';

class ShellTab {
  const ShellTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  /// A number on the icon, such as the items in the cart. 0 hides it.
  final int badge;
}

/// The frame around a role's pages: tabs at the bottom on phones, at the
/// side on wide screens. A tab keeps its state while another one is open.
class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({
    super.key,
    required this.tabs,
    required this.index,
    required this.onSelected,
  });

  final List<ShellTab> tabs;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  // Keeps the pages when the window is resized between the two layouts.
  final _stackKey = GlobalKey();

  // Pages are built the first time their tab is opened.
  final _opened = <int>{};

  void _select(int index) {
    // A message about the old tab would cover the new tab's buttons.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    widget.onSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    _opened.add(widget.index);
    final pages = IndexedStack(
      key: _stackKey,
      index: widget.index,
      children: [
        for (final (index, tab) in widget.tabs.indexed)
          _opened.contains(index) ? tab.page : const SizedBox.shrink(),
      ],
    );

    if (MediaQuery.sizeOf(context).width >= 840) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: widget.index,
                onDestinationSelected: _select,
                destinations: [
                  for (final tab in widget.tabs)
                    NavigationRailDestination(
                      icon: _icon(tab, tab.icon),
                      selectedIcon: _icon(tab, tab.selectedIcon),
                      label: Text(tab.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages),
          ],
        ),
      );
    }
    return Scaffold(
      body: pages,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.index,
        onDestinationSelected: _select,
        destinations: [
          for (final tab in widget.tabs)
            NavigationDestination(
              icon: _icon(tab, tab.icon),
              selectedIcon: _icon(tab, tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }

  Widget _icon(ShellTab tab, IconData icon) => Badge.count(
    count: tab.badge,
    isLabelVisible: tab.badge > 0,
    child: Icon(icon),
  );
}
