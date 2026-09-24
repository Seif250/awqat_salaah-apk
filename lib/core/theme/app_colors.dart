import 'package:flutter/material.dart';

class AppColors {
  // Primary - Deep Islamic Emerald & Forest Green
  static const Color primary = Color(0xFF0F5132);
  static const Color primaryLight = Color(0xFF198754);
  static const Color primaryDark = Color(0xFF0A3622);
  static const Color primaryContainer = Color(0xFFD1E7DD);

  // Accent - Warm Elegant Gold / Amber
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentGoldLight = Color(0xFFF3E5AB);
  static const Color accentAmber = Color(0xFFFFC107);

  // Dark Theme Backgrounds & Surfaces
  static const Color darkBackground = Color(0xFF0B1410);
  static const Color darkSurface = Color(0xFF13221B);
  static const Color darkCard = Color(0xFF1A2E25);
  static const Color darkCardElevated = Color(0xFF223C30);
  static const Color darkBorder = Color(0xFF2D4B3D);

  // Light Theme Backgrounds & Surfaces
  static const Color lightBackground = Color(0xFFF4F7F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFE8F3ED);
  static const Color lightBorder = Color(0xFFD8E5DF);

  // Status & Prayer Highlights
  static const Color activePrayer = Color(0xFF00C853);
  static const Color nextPrayerGlow = Color(0xFFD4AF37);
  static const Color passedPrayer = Color(0xFF78909C);
  static const Color iqamahActive = Color(0xFF48CAE4);
  static const Color iqamahActiveLight = Color(0xFF90E0EF);

  // Surface Variants & Selections
  static const Color darkSurfaceAlt = Color(0xFF13231B);
  static const Color darkSurfaceSelected = Color(0xFF1C3529);
  static const Color lightSurfaceSelected = Color(0xFFE8F5E9);

  // Gradients
  static const List<Color> iqamahCardGradient = [
    Color(0xFF1B4D3E),
    Color(0xFF10362A),
    Color(0xFF092018),
  ];
  static const List<Color> nextPrayerDarkGradient = [
    Color(0xFF193D2C),
    Color(0xFF10281D),
    Color(0xFF0A1912),
  ];
  static const List<Color> nextPrayerLightGradient = [
    Color(0xFF0F5132),
    Color(0xFF125C3A),
    Color(0xFF0A3D25),
  ];
  static const List<Color> locationBannerDarkGradient = [
    Color(0xFF132F23),
    Color(0xFF0C1D16),
  ];
  static const List<Color> locationBannerLightGradient = [
    Color(0xFF0F5132),
    Color(0xFF1B6A43),
  ];

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1A2E25);
  static const Color textSecondaryLight = Color(0xFF527063);
  static const Color textPrimaryDark = Color(0xFFF1F8F4);
  static const Color textSecondaryDark = Color(0xFFA5C4B4);
  static const Color azkarTextDark = Color(0xFFECEFF1);
  static const Color azkarTextLight = Color(0xFF263238);
}
