import 'package:flutter/material.dart';

import '../branding/app_branding.dart';
import '../theme/design_tokens.dart';
import 'pressable.dart';

/// Card padrão do design system — mesmo padrão usado no AlfaControl: raio
/// 16, padding 20, cor de fundo + borda de 1px, sem sombra. Usar em vez de
/// `Container` cru pra qualquer bloco de conteúdo agrupado (substitui a
/// repetição de `BoxDecoration` manual espalhada pelas telas do aluno).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: b.border),
      ),
      child: child,
    );
    final onTapCb = onTap;
    if (onTapCb == null) return content;
    return Pressable(
      onTap: onTapCb,
      borderRadius: AppRadius.card,
      child: content,
    );
  }
}
