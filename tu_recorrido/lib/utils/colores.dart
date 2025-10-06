import 'package:flutter/material.dart';

class Coloressito {
  // Paleta de colores gaming/aventura - inspirada en el Home
  
  // Colores principales del gradiente de fondo
  static const Color deepBlue = Color(0xFF1a237e);      // Azul profundo
  static const Color mediumBlue = Color(0xFF3949ab);     // Azul medio
  static const Color lightBlue = Color(0xFF5c6bc0);      // Azul claro
  
  // Colores de acento para elementos interactivos
  static const Color adventureGreen = Color(0xFF1DB954); // Verde aventura (botón principal)
  static const Color brightGreen = Color(0xFF1ed760);    // Verde brillante (gradiente)
  
  // Colores de insignias/elementos flotantes
  static const Color badgeRed = Color(0xFFe57373);       // Rojo insignia (ubicación)
  static const Color badgeYellow = Color(0xFFffb74d);    // Amarillo insignia (estrella)
  static const Color badgeGreen = Color(0xFF81c784);     // Verde insignia (cámara)
  static const Color badgeBlue = Color(0xFF64b5f6);      // Azul insignia (extra)
  
  // Colores de superficie y fondos
  static const Color backgroundDark = Color(0xFF0D1421);  // Fondo oscuro principal
  static const Color surfaceLight = Color(0x33FFFFFF);   // Blanco transparente para cards
  static const Color surfaceDark = Color(0x1AFFFFFF);    // Blanco muy transparente
  static const Color borderLight = Color(0x4DFFFFFF);    // Bordes blancos suaves
  
  // Textos
  static const Color textPrimary = Colors.white;         // Texto principal
  static const Color textSecondary = Color(0xB3FFFFFF);  // Texto secundario (70% opacidad)
  static const Color textMuted = Color(0x66FFFFFF);      // Texto muted (40% opacidad)
  
  // Sombras y efectos
  static const Color shadowColor = Color(0x33000000);    // Sombras sutiles
  static const Color glowColor = Color(0x661DB954);      // Efecto glow verde
  
  // Gradientes predefinidos
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepBlue, mediumBlue, lightBlue],
  );
  
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [adventureGreen, brightGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // Compatibilidad con código existente
  static const Color primary = deepBlue;
  static const Color secondary = adventureGreen;
  static const Color background = deepBlue;
}