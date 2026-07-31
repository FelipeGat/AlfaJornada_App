import 'package:flutter/material.dart';

import '../api/api_client.dart';

@immutable
class AppBranding extends ThemeExtension<AppBranding> {
  const AppBranding({
    required this.primary,
    required this.primarySoft,
    required this.textDark,
    required this.textMuted,
    required this.bg,
    required this.card,
    required this.border,
    required this.success,
    required this.danger,
    required this.warning,
    required this.label,
    required this.logoAsset,
  });

  final Color primary;
  final Color primarySoft;
  final Color textDark;
  final Color textMuted;
  final Color bg;
  final Color card;
  final Color border;
  final Color success;
  final Color danger;
  final Color warning;
  final String label;
  final String logoAsset;

  /// Azul oficial da marca AlfaJornada (`--color-brand: #2563EB` no
  /// frontend web) — símbolo "α-Percurso" replicado em
  /// `lib/features/jornada/branding/alfa_jornada_mark.dart`.
  static const AppBranding alfaJornada = AppBranding(
    primary: Color(0xFF2563EB),
    primarySoft: Color(0xFFDBEAFE),
    textDark: Color(0xFF1E293B),
    textMuted: Color(0xFF64748B),
    bg: Color(0xFFF3F4F6),
    card: Colors.white,
    border: Color(0xFFE5E7EB),
    success: Color(0xFF22C55E),
    danger: Color(0xFFDC2626),
    warning: Color(0xFFF59E0B),
    label: 'AlfaJornada',
    logoAsset: 'assets/app_icon/alfamobi-logo.png',
  );

  static const AppBranding alfaJornadaDark = AppBranding(
    primary: Color(0xFF60A5FA),
    primarySoft: Color(0xFF1E3A5F),
    textDark: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
    bg: Color(0xFF0F172A),
    card: Color(0xFF1E293B),
    border: Color(0xFF334155),
    success: Color(0xFF22C55E),
    danger: Color(0xFFF87171),
    warning: Color(0xFFFBBF24),
    label: 'AlfaJornada',
    logoAsset: 'assets/app_icon/alfamobi-logo.png',
  );

  static AppBranding forProduct(AlfaProduct? product, {bool dark = false}) {
    return dark ? alfaJornadaDark : alfaJornada;
  }

  static AppBranding of(BuildContext context) {
    final ext = Theme.of(context).extension<AppBranding>();
    return ext ?? alfaJornada;
  }

  @override
  AppBranding copyWith({
    Color? primary,
    Color? primarySoft,
    Color? textDark,
    Color? textMuted,
    Color? bg,
    Color? card,
    Color? border,
    Color? success,
    Color? danger,
    Color? warning,
    String? label,
    String? logoAsset,
  }) {
    return AppBranding(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      textDark: textDark ?? this.textDark,
      textMuted: textMuted ?? this.textMuted,
      bg: bg ?? this.bg,
      card: card ?? this.card,
      border: border ?? this.border,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      label: label ?? this.label,
      logoAsset: logoAsset ?? this.logoAsset,
    );
  }

  @override
  AppBranding lerp(ThemeExtension<AppBranding>? other, double t) {
    if (other is! AppBranding) return this;
    return AppBranding(
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      label: t < 0.5 ? label : other.label,
      logoAsset: t < 0.5 ? logoAsset : other.logoAsset,
    );
  }
}
