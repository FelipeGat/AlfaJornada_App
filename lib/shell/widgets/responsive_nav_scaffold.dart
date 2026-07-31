import 'package:flutter/material.dart';

import '../../core/branding/app_branding.dart';
import '../../core/responsive/breakpoints.dart';

class NavDestinationData {
  const NavDestinationData({
    required this.iconOutlined,
    required this.iconFilled,
    required this.label,
  });

  final IconData iconOutlined;
  final IconData iconFilled;
  final String label;
}

class ResponsiveNavScaffold extends StatelessWidget {
  const ResponsiveNavScaffold({
    super.key,
    required this.destinations,
    required this.tabs,
    required this.currentIndex,
    required this.onIndexChanged,
  }) : assert(destinations.length == tabs.length);

  final List<NavDestinationData> destinations;
  final List<Widget> tabs;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final body = IndexedStack(index: currentIndex, children: tabs);

    if (!context.isTabletWidth) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? b.primary
                    : b.textMuted,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onIndexChanged,
            backgroundColor: b.card,
            indicatorColor: b.primarySoft,
            destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.iconOutlined, color: b.textMuted),
                selectedIcon: Icon(d.iconFilled, color: b.primary),
                label: d.label,
              ),
            ],
          ),
        ),
      );
    }

    final extended = context.isExpandedWidth;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: extended,
              selectedIndex: currentIndex,
              onDestinationSelected: onIndexChanged,
              backgroundColor: b.card,
              indicatorColor: Colors.transparent,
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: b.primary),
              unselectedIconTheme: IconThemeData(color: b.textMuted),
              selectedLabelTextStyle: TextStyle(color: b.primary),
              unselectedLabelTextStyle: TextStyle(color: b.textMuted),
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.iconOutlined),
                    selectedIcon: Icon(d.iconFilled),
                    label: Text(d.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: b.border),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
