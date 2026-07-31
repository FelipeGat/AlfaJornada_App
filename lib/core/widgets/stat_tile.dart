import 'package:flutter/material.dart';

import '../branding/app_branding.dart';
import '../theme/design_tokens.dart';
import 'pressable.dart';

/// Tile de estatística padrão — ícone pequeno, número grande (tabular) e
/// descrição em caixa alta, mesmo tamanho em toda grade. Usado em
/// Home/Resumo, Meu Painel e Pagamentos.
///
/// Quando [comingSoon] é `true`, renderiza em estado "em breve" (acinzentado,
/// sem inventar número) — pra métricas sem fonte de dado real ainda.
class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
    this.comingSoon = false,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;
  final bool comingSoon;
  final VoidCallback? onTap;

  /// Usar em grades apertadas (ex.: 3 tiles lado a lado) — reduz o tamanho
  /// do número pra caber sem quebrar/estourar.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: b.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: b.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: comingSoon ? b.textMuted.withValues(alpha: 0.5) : b.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            comingSoon ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypeScale.subtitulo.copyWith(
              fontSize: compact ? 16 : null,
              color: comingSoon ? b.textMuted : (valueColor ?? b.textDark),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            comingSoon ? '$label · em breve' : label,
            maxLines: 2,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: b.textMuted,
            ),
          ),
        ],
      ),
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
