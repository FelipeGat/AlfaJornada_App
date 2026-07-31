import 'package:flutter/material.dart';

/// Raios padrão do redesign "Premium" do AlfaGym — fonte única de verdade
/// pra não espalhar números mágicos pelos widgets.
class AppRadius {
  const AppRadius._();
  static const double card = 16;
  static const double button = 14;
  static const double input = 12;
}

/// Espaçamento em grid de 8px.
class AppSpacing {
  const AppSpacing._();
  static const double grid = 8;
  static const double cardPadding = 20;
  static const double cardGap = 16;
}

/// Escala tipográfica única do app (Título/Subtítulo/Texto/Descrição) —
/// nunca misturar tamanhos fora desses 4. Cor é sempre aplicada no ponto de
/// uso via `.copyWith(color: ...)`, nunca fixa aqui.
class AppTypeScale {
  const AppTypeScale._();
  static const TextStyle titulo = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );
  static const TextStyle subtitulo = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle texto = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const TextStyle descricao = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
