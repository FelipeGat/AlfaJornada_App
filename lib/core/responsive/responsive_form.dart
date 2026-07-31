import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Centraliza o body de um form em tablet (limita largura a `maxWidth`)
/// e deixa intocado em phone. Aplicar logo depois do `Scaffold.body`/
/// `SingleChildScrollView` pra evitar que TextFields se estiquem por
/// 1100 dp em landscape.
class ResponsiveFormScaffold extends StatelessWidget {
  const ResponsiveFormScaffold({
    super.key,
    required this.child,
    this.maxWidth = 900,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!context.isTabletWidth) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Renderiza uma sequência de campos curtos (CPF, telefone, CEP, UF,
/// data, valor) em coluna em phone e em grid 2-col em tablet. Campos
/// longos (descrição, observações, endereço) ficam fora do grid.
///
/// O grid usa `Wrap` com `SizedBox(width: (maxW - spacing) / 2)`. Cada
/// filho deve ser auto-contido: rótulo + input + erro próprios.
class ResponsiveFormGrid extends StatelessWidget {
  const ResponsiveFormGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.tabletColumns = 2,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int tabletColumns;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (!context.isTabletWidth) {
      // Em phone, empilhar verticalmente preservando o spacing original
      // entre filhos. Cada filho deve ter sua própria altura intrínseca.
      final out = <Widget>[];
      for (var i = 0; i < children.length; i++) {
        if (i > 0) out.add(SizedBox(height: runSpacing));
        out.add(children[i]);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: out,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = tabletColumns;
        final totalSpacing = spacing * (cols - 1);
        final colWidth = (constraints.maxWidth - totalSpacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final c in children)
              SizedBox(width: colWidth, child: c),
          ],
        );
      },
    );
  }
}
