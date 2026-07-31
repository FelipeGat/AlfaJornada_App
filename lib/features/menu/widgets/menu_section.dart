import 'package:flutter/material.dart';

import '../../../core/branding/app_branding.dart';

/// Título de seção estilo iOS (caixa alta, peso forte, letter-spacing).
/// Usado na MenuScreen pra agrupar blocos (CONTA / PREFERÊNCIAS / SOBRE).
class MenuSection extends StatelessWidget {
  const MenuSection({
    super.key,
    required this.titulo,
    required this.child,
  });

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            titulo.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: b.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Card arredondado que agrupa `ListTile`s internos. Reusa o visual padrão
/// usado em ConfiguracoesScreen.
class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    return Container(
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: b.border),
            children[i],
          ],
        ],
      ),
    );
  }
}
