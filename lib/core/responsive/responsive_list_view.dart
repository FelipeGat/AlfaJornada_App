import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Renderiza uma coleção paginada como `ListView.builder` em phone
/// (compact) e `GridView.builder` 2/3 colunas em tablet/expanded.
///
/// Mantém um único `ScrollController`/`padding`/`itemBuilder` pra que
/// o scroll-triggered pagination dos providers continue funcionando
/// (o threshold de 280 px do `extentAfter` é independente do delegate).
///
/// Em tablet o card mantém o mesmo widget — só o layout muda. O
/// aspectRatio padrão (3.4) cabe bem cards horizontais com avatar +
/// 2 linhas de texto + chevron. Cards mais "quadrados" (ex.: tile
/// gráfico) podem passar `tabletAspectRatio` próprio.
class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.physics,
    this.compactSeparator,
    this.tabletAspectRatio = 3.4,
    this.tabletCrossAxisSpacing = 12,
    this.tabletMainAxisSpacing = 12,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  /// Quando informado, em compact (phone) usa `ListView.separated` com
  /// esse builder. Em tablet o separador é ignorado (spacing controla).
  final IndexedWidgetBuilder? compactSeparator;

  final double tabletAspectRatio;
  final double tabletCrossAxisSpacing;
  final double tabletMainAxisSpacing;

  @override
  Widget build(BuildContext context) {
    if (!context.isTabletWidth) {
      if (compactSeparator != null) {
        return ListView.separated(
          controller: controller,
          padding: padding,
          physics: physics,
          itemCount: itemCount,
          separatorBuilder: compactSeparator!,
          itemBuilder: itemBuilder,
        );
      }
      return ListView.builder(
        controller: controller,
        padding: padding,
        physics: physics,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }

    final cols = responsiveCrossAxisCount(
      context,
      compact: 1,
      medium: 2,
      expanded: 3,
    );

    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: tabletCrossAxisSpacing,
        mainAxisSpacing: tabletMainAxisSpacing,
        childAspectRatio: tabletAspectRatio,
      ),
      itemBuilder: itemBuilder,
    );
  }
}
