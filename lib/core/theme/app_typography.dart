import 'package:flutter/material.dart';

/// Centralized typography scale and text style builders for Wird.
/// Uses locally bundled `IBMPlexSansArabic` for clean tabular prayer times,
/// open Arabic legibility across font scales, and calm editorial hierarchy.
class AppTypography {
  AppTypography._();

  static const String uiFont = 'IBMPlexSansArabic';
  static const List<String> uiFallback = ['IBMPlexSansArabic', 'Cairo', 'sans-serif'];

  static TextTheme buildTextTheme(TextTheme base, Color primary, Color secondary) {
    return base
        .copyWith(
          headlineLarge: heroTitle(primary),
          headlineMedium: pageTitle(primary),
          titleLarge: pageTitle(primary),
          titleMedium: sectionHeader(primary),
          titleSmall: rowTitle(primary),
          bodyLarge: body(primary),
          bodyMedium: body(primary, size: 14.5),
          bodySmall: meta(secondary),
          labelLarge: label(primary),
          labelMedium: meta(secondary),
          labelSmall: badge(secondary),
        )
        .apply(
          fontFamily: uiFont,
          bodyColor: primary,
          displayColor: primary,
        );
  }

  static TextStyle heroCountdown(Color color) => TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 1.08,
        letterSpacing: 0.6,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  static TextStyle heroTitle(Color color) => TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: 27,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: color,
      );

  static TextStyle pageTitle(Color color) => TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: color,
      );

  static TextStyle sectionHeader(Color color) => TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color,
      );

  static TextStyle rowTitle(Color color, {FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: 15,
        fontWeight: weight,
        height: 1.35,
        color: color,
      );

  static TextStyle timeValue(
    Color color, {
    double size = 15.5,
    FontWeight weight = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: size,
        fontWeight: weight,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: color,
      );

  static TextStyle body(
    Color color, {
    double size = 15,
    double height = 1.55,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );

  static TextStyle dhikrBody(
    Color color, {
    double scale = 1.0,
    bool isQuranic = false,
  }) =>
      TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: (isQuranic ? 17.5 : 16.5) * scale,
        fontWeight: isQuranic ? FontWeight.w500 : FontWeight.w500,
        height: isQuranic ? 1.8 : 1.72,
        color: color,
      );

  static TextStyle meta(
    Color color, {
    double size = 12,
    FontWeight weight = FontWeight.w500,
    double height = 1.4,
  }) =>
      TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );

  static TextStyle label(
    Color color, {
    double size = 13,
    FontWeight weight = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: size,
        fontWeight: weight,
        height: 1.3,
        color: color,
      );

  static TextStyle badge(
    Color color, {
    double size = 11,
    FontWeight weight = FontWeight.w600,
  }) =>
      TextStyle(
        fontFamily: uiFont,
        fontFamilyFallback: uiFallback,
        fontSize: size,
        fontWeight: weight,
        height: 1.25,
        color: color,
      );
}
