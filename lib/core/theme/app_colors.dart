import 'package:flutter/material.dart';
class AppColors {
  AppColors._();

  static const Color gradientStart = Color(0xFF1E3A8A); // azul oscuro
  static const Color gradientMid = Color(0xFF2E4FC4); // azul medio
  static const Color gradientEnd = Color(0xFF4C3FBF); // azul-violeta sutil

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  /// tarjeta del evento destacado en el home azul profundo → morado.
  static const Color eventHeroStart = Color(0xFF262B7A);
  static const Color eventHeroMid = Color(0xFF33339A);
  static const Color eventHeroEnd = Color(0xFF4B3DB0);

  static const LinearGradient eventHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [eventHeroStart, eventHeroMid, eventHeroEnd],
  );

  static const Color eventHeroShadow = Color(0x553D3A9E);

  /// botón central del menú flotante azul → celeste.
  static const LinearGradient navCenterGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F6BF5), Color(0xFF5ED0F7)],
  );

  static const Color primary = Color(0xFF2E4FC4);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryLight = Color(0xFF5A73F6);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F5FA);

  static const Color textPrimary = Color(0xFF181C45);
  static const Color textSecondary = Color(0xFF6B7194);
  static const Color textMuted = Color(0xFF9CA1BC);
  static const Color onPrimaryMuted = Color(0xFFDCE3FF);

  static const Color border = Color(0xFFE6E8F2);
  static const Color transparent = Color(0x00000000);

  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);

  static const Color chipBackground = Color(0x142E4FC4); // primary 8%
  static const Color avatarBackground = Color(0x1F2E4FC4); // primary 12%
  static const Color iconTileBackground = Color(0x1A2E4FC4); // primary 10%
  static const Color glassOnGradient = Color(0x1FFFFFFF); // blanco 12%
  static const Color glassBorderOnGradient = Color(0x40FFFFFF); // blanco 25%

  static const Color socialInstagram = Color(0xFFD62976);
  static const Color socialLinkedin = Color(0xFF0A66C2);
  static const Color socialTikTok = Color(0xFF111827);

  static const Color institutionsColor = Color(0xFF2DC0B0);
  static const Color speakersColor = Color(0xFFE8734A); // ejemplo de color para estudiantes
  static const Color calendarColor = Color(0xFF5A73F6);
  static const Color mapColor = Color(0xFF3B82F6);
  static const Color galleryColor = Color(0xFF8B5CF6);

  /// Fondo teal suave de la organización seleccionada en formularios.
  static const Color selectedTealBackground = Color(0xFFE6F8F5);

  /// Estado "en vivo": punto celeste sobre la tarjeta oscura y badge
  /// naranja suave sobre fondo claro.
  static const Color liveDot = Color(0xFF5ED0F7);
  static const Color liveBadge = Color(0xFFE8734A);
  static const Color liveBadgeBackground = Color(0xFFFDECE6);

  static const Color navBackground = Color(0xFF232A6B);
  static const Color navIconInactive = Color(0xFF9BA5C4);
  static const Color navActiveOverlay = Color(0x33FFFFFF); // blanco 20%
  static const Color navShadow = Color(0x40232A6B);
}
