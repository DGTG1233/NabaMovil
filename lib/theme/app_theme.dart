import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const fondo = Color(0xFFFFFFFF);
  static const texto = Color(0xFF111111);
  static const textoSecundario = Color(0xFF6B7280);
  static const borde = Color(0xFFE5E7EB);
  static const superficie = Color(0xFFF7F7F8);
  static const positivo = Color(0xFF16A34A);
  static const negativo = Color(0xFFDC2626);
  static const azulNabame = Color(0xFF019DF4);
  static const marinoNabame = Color(0xFF0B2739);
  static const marinoOscuro = Color(0xFF061018);
}

class AppTheme {
  static ThemeData get tema {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fondo,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.azulNabame,
        secondary: AppColors.azulNabame,
        surface: AppColors.fondo,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.texto,
        displayColor: AppColors.texto,
      ),
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.fondo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.texto),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.texto,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.azulNabame, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.negativo, width: 1.2),
        ),
        labelStyle: const TextStyle(color: AppColors.textoSecundario),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.azulNabame,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.azulNabame.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
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

/// Tipografía reservada para títulos grandes (pantallas de acceso,
/// encabezados de sección). Usa Sora en vez de Inter para que los
/// títulos tengan más presencia que el texto de cuerpo.
class AppTypography {
  static TextStyle titulo({
    double size = 26,
    FontWeight weight = FontWeight.w800,
    Color color = AppColors.marinoNabame,
  }) {
    return GoogleFonts.sora(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.5,
    );
  }
}