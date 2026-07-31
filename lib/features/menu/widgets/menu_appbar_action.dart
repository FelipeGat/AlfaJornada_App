import 'package:flutter/material.dart';

import '../screens/menu_screen.dart';

/// Botão hamburger reusado como AppBar action em Home/Treino/Av.Física/
/// Evolução — abre o Menu escondido (Perfil, Minha agenda,
/// Configurações, Sobre, Sair). Faz push simples pra preservar o
/// bottom nav no destino.
class MenuAppBarAction extends StatelessWidget {
  const MenuAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      ),
    );
  }
}
