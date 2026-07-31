import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Renderiza uma sequência de tiles em coluna única (phone) ou em grid
/// 2/3 colunas (tablet/expanded). Pensado pros hubs SaaS e do aluno
/// que hoje usam `ListView` com `_Tile` (ListTile envelopado).
///
/// Em tablet vira `GridView.count` com `shrinkWrap` + `NeverScrollable`
/// pra continuar dentro de outro scroll (hub principal).
class AdaptiveTileSection extends StatelessWidget {
  const AdaptiveTileSection({
    super.key,
    required this.children,
    this.tabletAspectRatio = 3.6,
  });

  final List<Widget> children;
  final double tabletAspectRatio;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (!context.isTabletWidth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    final cols = responsiveCrossAxisCount(
      context,
      compact: 1,
      medium: 2,
      expanded: 3,
    );

    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: tabletAspectRatio,
      children: children,
    );
  }
}
