import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../branding/app_branding.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData fromBranding(AppBranding b) =>
      _build(b, ThemeData.light(useMaterial3: true));

  static ThemeData darkFromBranding(AppBranding b) =>
      _build(b, ThemeData.dark(useMaterial3: true));

  static ThemeData _build(AppBranding b, ThemeData base) {
    const cardRadius = 20.0;
    const buttonRadius = AppRadius.button;
    const inputRadius = AppRadius.input;
    return base.copyWith(
      scaffoldBackgroundColor: b.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: b.primary,
        onPrimary: Colors.white,
        primaryContainer: b.primarySoft,
        onPrimaryContainer: b.primary,
        secondary: b.primary,
        onSecondary: Colors.white,
        secondaryContainer: b.primarySoft,
        onSecondaryContainer: b.textDark,
        surface: b.card,
        onSurface: b.textDark,
        error: b.danger,
      ),
      extensions: [b],
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: b.textDark,
        displayColor: b.textDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: b.card,
        foregroundColor: b.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: b.textDark,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: b.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      dividerColor: b.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: b.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: b.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: b.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: b.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: b.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: b.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          // Altura mínima 52 — botão CRESCE quando texto vira 2 linhas
          // (ex.: usuário com Texto Grande + Negrito ativados na
          // Acessibilidade). Padding interno garante respiro vertical.
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
