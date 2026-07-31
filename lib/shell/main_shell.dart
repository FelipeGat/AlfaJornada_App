import 'package:flutter/material.dart';

import '../features/home/screens/home_screen.dart';
import '../features/jornada/screens/historico_ponto_screen.dart';
import '../features/menu/screens/menu_screen.dart';
import 'widgets/responsive_nav_scaffold.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    HistoricoPontoScreen(),
    MenuScreen(),
  ];

  static const _destinations = [
    NavDestinationData(
      iconOutlined: Icons.home_outlined,
      iconFilled: Icons.home,
      label: 'Home',
    ),
    NavDestinationData(
      iconOutlined: Icons.history_outlined,
      iconFilled: Icons.history,
      label: 'Histórico',
    ),
    NavDestinationData(
      iconOutlined: Icons.menu,
      iconFilled: Icons.menu,
      label: 'Menu',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      destinations: _destinations,
      tabs: _tabs,
      currentIndex: _index,
      onIndexChanged: (i) => setState(() => _index = i),
    );
  }
}
