import 'package:flutter/material.dart';

import '../branding/app_branding.dart';
import '../theme/design_tokens.dart';
import 'app_card.dart';

/// Card de resumo de um treino concluído — nome, "quando", duração e
/// volume levantado. Compartilhado entre a Home ("último treino") e a
/// tela de conclusão de treino (mesmo dado, mesmo layout).
class ResumoTreinoCard extends StatelessWidget {
  const ResumoTreinoCard({
    super.key,
    required this.titulo,
    this.templateNome,
    this.quando,
    this.duracaoMinutos,
    required this.numeroSeries,
    required this.volumeTotalKg,
  });

  final String titulo;
  final String? templateNome;
  final String? quando;
  final int? duracaoMinutos;
  final int numeroSeries;
  final double volumeTotalKg;

  @override
  Widget build(BuildContext context) {
    final b = AppBranding.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppTypeScale.descricao.copyWith(color: b.textMuted)),
          const SizedBox(height: 4),
          Text(
            templateNome ?? 'Treino',
            style: AppTypeScale.subtitulo.copyWith(color: b.textDark),
          ),
          if (quando != null) ...[
            const SizedBox(height: 2),
            Text(quando!, style: AppTypeScale.descricao.copyWith(color: b.textMuted)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (duracaoMinutos != null)
                _Metrica(icon: Icons.timer_outlined, valor: '$duracaoMinutos min', branding: b),
              if (duracaoMinutos != null) const SizedBox(width: 20),
              _Metrica(icon: Icons.repeat_rounded, valor: '$numeroSeries séries', branding: b),
              const SizedBox(width: 20),
              _Metrica(
                icon: Icons.fitness_center_rounded,
                valor: '${volumeTotalKg.toStringAsFixed(0)} kg',
                branding: b,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.icon, required this.valor, required this.branding});
  final IconData icon;
  final String valor;
  final AppBranding branding;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: branding.primary),
        const SizedBox(width: 6),
        Text(
          valor,
          style: AppTypeScale.texto.copyWith(fontWeight: FontWeight.w700, color: branding.textDark),
        ),
      ],
    );
  }
}
