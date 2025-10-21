import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema centralizado de la app basado en Material 3.
///
/// Colores base (inspirados en el diseño propuesto):
/// - primary: #157F3D (verde principal)
/// - secondary: #1E88E5 (azul acento)
/// - tertiary: #FF7043 (coral)
/// - background: #F7F8FA
class AppTheme {
  AppTheme._();

  static const _primary = Color(0xFF157F3D);
  static const _secondary = Color(0xFF1E88E5);
  static const _tertiary = Color(0xFFFF7043);
  static const _background = Color(0xFFF7F8FA);
  static const _surface = Colors.white;
  static const _onSurface = Color(0xFF1F2937); // gris oscuro para texto
  static const _onSurfaceVariant = Color(0xFF4B5563);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      secondary: _secondary,
      tertiary: _tertiary,
      surface: _surface,
    );

    final baseText = GoogleFonts.interTextTheme();
    final textTheme = baseText.apply(
      bodyColor: _onSurface,
      displayColor: _onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _surface,
        elevation: 0,
        foregroundColor: _onSurface,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: _onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        surfaceTintColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFE5E7EB)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _onSurface,
          side: BorderSide(color: _onSurfaceVariant.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      // Puedes añadir más temas (Chip, FAB, etc.) según se necesite
    );
  }
}
