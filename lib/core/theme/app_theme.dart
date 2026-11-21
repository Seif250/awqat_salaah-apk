import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/page_transitions.dart';
import 'app_color_palette.dart';
import 'app_typography.dart';

class AppTheme {
  static const String fontFamily = AppTypography.uiFont;

  static ThemeData buildTheme(AppColorPalette palette, Brightness brightness) {
    final p = WirdPalette.of(palette, brightness);
    final effectiveDark = p.isDark;
    final baseTextTheme = effectiveDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = AppTypography.buildTextTheme(
      baseTextTheme,
      p.textPrimary,
      p.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.uiFont,
      fontFamilyFallback: AppTypography.uiFallback,
      brightness: effectiveDark ? Brightness.dark : Brightness.light,
      colorScheme: effectiveDark
          ? ColorScheme.dark(
              primary: p.primaryLight,
              onPrimary: p.onPrimary,
              primaryContainer: p.primaryContainer,
              onPrimaryContainer: p.accentLight,
              secondary: p.accent,
              onSecondary: Colors.black,
              surface: p.surface,
              onSurface: p.textPrimary,
              onSurfaceVariant: p.textSecondary,
              outline: p.border,
              outlineVariant: p.border.withValues(alpha: 0.6),
            )
          : ColorScheme.light(
              primary: p.primary,
              onPrimary: p.onPrimary,
              primaryContainer: p.primaryContainer,
              onPrimaryContainer: p.textPrimary,
              secondary: p.accent,
              onSecondary: Colors.white,
              surface: p.surface,
              onSurface: p.textPrimary,
              onSurfaceVariant: p.textSecondary,
              outline: p.border,
              outlineVariant: p.border.withValues(alpha: 0.7),
            ),
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 0.8,
        space: 1,
      ),
      iconTheme: IconThemeData(color: p.textPrimary, size: 22),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border, width: 0.8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: p.border, width: 0.8),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              effectiveDark ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              effectiveDark ? Brightness.dark : Brightness.light,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: AppTypography.pageTitle(p.textPrimary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return effectiveDark ? p.accent : p.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return effectiveDark ? p.cardElevated : p.primaryContainer;
          }
          return null;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 44),
          textStyle: AppTypography.label(p.onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentText,
          minimumSize: const Size(48, 44),
          textStyle: AppTypography.label(p.accentText),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[p],
    );
  }

  static ThemeData get lightTheme =>
      buildTheme(AppColorPalette.goldenMushaf, Brightness.light);

  static ThemeData get darkTheme =>
      buildTheme(AppColorPalette.goldenMushaf, Brightness.dark);
}
