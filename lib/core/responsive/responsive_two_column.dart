import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Renderiza dois filhos lado-a-lado em tablet expanded (≥ 840 dp),
/// empilhados verticalmente em compact/medium. Pensado pra dashboards
/// e detalhes onde dois cards (ex.: receita+despesa, top alunos+top
/// funcionários, contratos vencendo+cancelamentos) ficam ocupando
/// linha inteira e podem dividir o espaço quando há largura.
///
/// O `spacing` controla tanto `width` da Row quanto `height` da Column.
class ResponsiveTwoColumn extends StatelessWidget {
  const ResponsiveTwoColumn({
    super.key,
    required this.first,
    required this.second,
    this.spacing = 12,
    this.flexFirst = 1,
    this.flexSecond = 1,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final Widget first;
  final Widget second;
  final double spacing;
  final int flexFirst;
  final int flexSecond;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (!context.isExpandedWidth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          SizedBox(height: spacing),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(flex: flexFirst, child: first),
        SizedBox(width: spacing),
        Expanded(flex: flexSecond, child: second),
      ],
    );
  }
}
