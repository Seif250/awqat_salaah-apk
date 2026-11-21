import 'package:flutter/material.dart';

/// Selectable visual color palettes for Wird (v3.0 — Bright Daylight & Calm Hierarchy).
/// Preserves existing enum names for backwards-compatible persistence.
enum AppColorPalette {
  goldenMushaf,
  royalEmerald,
  sepiaParchment,
  midnightSapphire,
  amoledGold,
}

extension AppColorPaletteExtension on AppColorPalette {
  String get storageKey => name;

  static AppColorPalette fromStorageKey(String? key) {
    if (key == null) return AppColorPalette.goldenMushaf;
    return AppColorPalette.values.firstWhere(
      (p) => p.name == key,
      orElse: () => AppColorPalette.goldenMushaf,
    );
  }

  String get titleArabic {
    switch (this) {
      case AppColorPalette.goldenMushaf:
        return 'الإشراق الهادئ';
      case AppColorPalette.royalEmerald:
        return 'الزمردي النقي';
      case AppColorPalette.sepiaParchment:
        return 'الكتّان الدافئ';
      case AppColorPalette.midnightSapphire:
        return 'سماء الضحى';
      case AppColorPalette.amoledGold:
        return 'الليلي الخالص (AMOLED)';
    }
  }

  String get subtitleArabic {
    switch (this) {
      case AppColorPalette.goldenMushaf:
        return 'أبيض لؤلؤي مشرق مع زمردي هادئ ولمسة ذهبية معتدلة';
      case AppColorPalette.royalEmerald:
        return 'بياض ناصع مع أخضر زمردي كلاسيكي واضح التباين';
      case AppColorPalette.sepiaParchment:
        return 'خلفية كتّانية فاتحة ومريحة للعين أثناء القراءة';
      case AppColorPalette.midnightSapphire:
        return 'إضاءة نهارية صافية بدرجات الأزرق الهادئ';
      case AppColorPalette.amoledGold:
        return 'أسود خالص لشاشات OLED وراحة تامة ليلاً';
    }
  }

  /// Three swatch colors for visual theme picker previews: [canvas, primary, accent].
  List<Color> get previewColors {
    switch (this) {
      case AppColorPalette.goldenMushaf:
        return const [Color(0xFFFAFBF9), Color(0xFF165B44), Color(0xFFB88B28)];
      case AppColorPalette.royalEmerald:
        return const [Color(0xFFF7FAF8), Color(0xFF0F5132), Color(0xFFC5962C)];
      case AppColorPalette.sepiaParchment:
        return const [Color(0xFFFAF8F3), Color(0xFF5C4930), Color(0xFFB5852E)];
      case AppColorPalette.midnightSapphire:
        return const [Color(0xFFF7FAFE), Color(0xFF1B4980), Color(0xFFC2962E)];
      case AppColorPalette.amoledGold:
        return const [Color(0xFF000000), Color(0xFF2B7A5E), Color(0xFFD8B355)];
    }
  }

  bool get forcesDarkMode => this == AppColorPalette.amoledGold;
}

class WirdPalette extends ThemeExtension<WirdPalette> {
  final AppColorPalette id;
  final bool isDark;
  final Color primary;
  final Color primaryLight;
  final Color primaryContainer;
  final Color onPrimary;
  final Color accent;
  final Color accentLight;
  final Color background;
  final Color surface;
  final Color card;
  final Color cardElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color iqamah;
  final Color iqamahContainer;
  final Color success;
  final Color sunrise;
  final Color dhikrContainerBg;
  final Color dhikrContainerBorder;
  final Color quranParchmentBg;
  final Color quranParchmentBorder;
  final Color virtueBg;
  final Color virtueBorder;
  final Color completedCardBg;
  final Color completedCardBorder;
  final Color navActiveBg;

  const WirdPalette({
    required this.id,
    required this.isDark,
    required this.primary,
    required this.primaryLight,
    required this.primaryContainer,
    required this.onPrimary,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.surface,
    required this.card,
    required this.cardElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.iqamah,
    required this.iqamahContainer,
    required this.success,
    required this.sunrise,
    required this.dhikrContainerBg,
    required this.dhikrContainerBorder,
    required this.quranParchmentBg,
    required this.quranParchmentBorder,
    required this.virtueBg,
    required this.virtueBorder,
    required this.completedCardBg,
    required this.completedCardBorder,
    required this.navActiveBg,
  });

  /// High-contrast accent text safe for small labels on the current surface:
  /// avoids weak light gold on bright backgrounds.
  Color get accentText => isDark ? accentLight : primary;

  /// Soft hairline divider color.
  Color get hairline => border;

  /// Semantic error color with strong contrast in both modes.
  Color get error => isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

  /// Deepest anchor tint paired with [primary] for photo scrims and compass dial.
  Color get primaryDark => isDark ? const Color(0xFF0A241A) : const Color(0xFF0E3D2E);

  /// Elevation shadow tint.
  Color get shadowColor => Colors.black;

  factory WirdPalette.of(AppColorPalette palette, Brightness brightness) {
    final dark = brightness == Brightness.dark || palette.forcesDarkMode;

    switch (palette) {
      case AppColorPalette.goldenMushaf:
        if (!dark) {
          return const WirdPalette(
            id: AppColorPalette.goldenMushaf,
            isDark: false,
            primary: Color(0xFF165B44),
            primaryLight: Color(0xFF237A5D),
            primaryContainer: Color(0xFFE6F2EC),
            onPrimary: Colors.white,
            accent: Color(0xFFB88B28),
            accentLight: Color(0xFFDFBC62),
            background: Color(0xFFFAFBF9),
            surface: Color(0xFFFFFFFF),
            card: Color(0xFFFFFFFF),
            cardElevated: Color(0xFFEEF5F0),
            border: Color(0xFFE4EAE6),
            textPrimary: Color(0xFF13201B),
            textSecondary: Color(0xFF52615B),
            iqamah: Color(0xFF0E7490),
            iqamahContainer: Color(0xFFE6F4F7),
            success: Color(0xFF15803D),
            sunrise: Color(0xFFB45309),
            dhikrContainerBg: Color(0xFFF6F9F7),
            dhikrContainerBorder: Color(0xFFE5ECE8),
            quranParchmentBg: Color(0xFFFAF8F2),
            quranParchmentBorder: Color(0xFFE9E2D0),
            virtueBg: Color(0xFFF4F7F5),
            virtueBorder: Color(0xFFE2EAE5),
            completedCardBg: Color(0xFFEDF6F0),
            completedCardBorder: Color(0xFF9AC5AA),
            navActiveBg: Color(0xFFE5F1EB),
          );
        }
        return const WirdPalette(
          id: AppColorPalette.goldenMushaf,
          isDark: true,
          primary: Color(0xFF2B7A5E),
          primaryLight: Color(0xFF459A7B),
          primaryContainer: Color(0xFF193228),
          onPrimary: Colors.white,
          accent: Color(0xFFD6AE4F),
          accentLight: Color(0xFFEDD182),
          background: Color(0xFF0E1311),
          surface: Color(0xFF151C19),
          card: Color(0xFF1A231F),
          cardElevated: Color(0xFF212E28),
          border: Color(0xFF293731),
          textPrimary: Color(0xFFF1F5F3),
          textSecondary: Color(0xFF9FB0A9),
          iqamah: Color(0xFF67D4EA),
          iqamahContainer: Color(0xFF11353E),
          success: Color(0xFF4ADE80),
          sunrise: Color(0xFFFBBF24),
          dhikrContainerBg: Color(0xFF1A231F),
          dhikrContainerBorder: Color(0xFF293731),
          quranParchmentBg: Color(0xFF1D221D),
          quranParchmentBorder: Color(0xFF313930),
          virtueBg: Color(0xFF141B18),
          virtueBorder: Color(0xFF25322C),
          completedCardBg: Color(0xFF12281D),
          completedCardBorder: Color(0xFF2A5E44),
          navActiveBg: Color(0xFF1B3329),
        );

      case AppColorPalette.royalEmerald:
        if (!dark) {
          return const WirdPalette(
            id: AppColorPalette.royalEmerald,
            isDark: false,
            primary: Color(0xFF0F5132),
            primaryLight: Color(0xFF1B6E47),
            primaryContainer: Color(0xFFE2F1E8),
            onPrimary: Colors.white,
            accent: Color(0xFFC5962C),
            accentLight: Color(0xFFE7C770),
            background: Color(0xFFF7FAF8),
            surface: Color(0xFFFFFFFF),
            card: Color(0xFFFFFFFF),
            cardElevated: Color(0xFFEAF3ED),
            border: Color(0xFFE0E9E3),
            textPrimary: Color(0xFF112219),
            textSecondary: Color(0xFF4F6359),
            iqamah: Color(0xFF0E7490),
            iqamahContainer: Color(0xFFE6F4F7),
            success: Color(0xFF15803D),
            sunrise: Color(0xFFB45309),
            dhikrContainerBg: Color(0xFFF5F9F6),
            dhikrContainerBorder: Color(0xFFE2EBE5),
            quranParchmentBg: Color(0xFFFAF8F2),
            quranParchmentBorder: Color(0xFFE8E1CF),
            virtueBg: Color(0xFFF1F6F3),
            virtueBorder: Color(0xFFDDE8E1),
            completedCardBg: Color(0xFFE7F3EC),
            completedCardBorder: Color(0xFF8EC0A3),
            navActiveBg: Color(0xFFE2F1E8),
          );
        }
        return const WirdPalette(
          id: AppColorPalette.royalEmerald,
          isDark: true,
          primary: Color(0xFF24744F),
          primaryLight: Color(0xFF399369),
          primaryContainer: Color(0xFF163225),
          onPrimary: Colors.white,
          accent: Color(0xFFD4AF37),
          accentLight: Color(0xFFF1D788),
          background: Color(0xFF0C1410),
          surface: Color(0xFF13201A),
          card: Color(0xFF192A22),
          cardElevated: Color(0xFF20362C),
          border: Color(0xFF2B4337),
          textPrimary: Color(0xFFEFF6F2),
          textSecondary: Color(0xFFA0B8AD),
          iqamah: Color(0xFF67D4EA),
          iqamahContainer: Color(0xFF11353E),
          success: Color(0xFF4ADE80),
          sunrise: Color(0xFFFBBF24),
          dhikrContainerBg: Color(0xFF192A22),
          dhikrContainerBorder: Color(0xFF2B4337),
          quranParchmentBg: Color(0xFF1D2921),
          quranParchmentBorder: Color(0xFF314436),
          virtueBg: Color(0xFF12201A),
          virtueBorder: Color(0xFF253B30),
          completedCardBg: Color(0xFF112C1F),
          completedCardBorder: Color(0xFF276649),
          navActiveBg: Color(0xFF183829),
        );

      case AppColorPalette.sepiaParchment:
        if (!dark) {
          return const WirdPalette(
            id: AppColorPalette.sepiaParchment,
            isDark: false,
            primary: Color(0xFF5C4930),
            primaryLight: Color(0xFF7A6344),
            primaryContainer: Color(0xFFF1ECE1),
            onPrimary: Colors.white,
            accent: Color(0xFFB5852E),
            accentLight: Color(0xFFDCB466),
            background: Color(0xFFFAF8F3),
            surface: Color(0xFFFFFFFF),
            card: Color(0xFFFFFFFF),
            cardElevated: Color(0xFFF2EFE6),
            border: Color(0xFFE8E2D5),
            textPrimary: Color(0xFF241D14),
            textSecondary: Color(0xFF685A47),
            iqamah: Color(0xFF0E7490),
            iqamahContainer: Color(0xFFE6F4F7),
            success: Color(0xFF2E6B40),
            sunrise: Color(0xFFB45309),
            dhikrContainerBg: Color(0xFFF8F5EE),
            dhikrContainerBorder: Color(0xFFE9E2D4),
            quranParchmentBg: Color(0xFFFAF6EB),
            quranParchmentBorder: Color(0xFFE6DEC8),
            virtueBg: Color(0xFFF5F1E7),
            virtueBorder: Color(0xFFE5DEC9),
            completedCardBg: Color(0xFFEDF2E8),
            completedCardBorder: Color(0xFF9BB48E),
            navActiveBg: Color(0xFFF1ECE1),
          );
        }
        return const WirdPalette(
          id: AppColorPalette.sepiaParchment,
          isDark: true,
          primary: Color(0xFF9C7B4E),
          primaryLight: Color(0xFFBA9664),
          primaryContainer: Color(0xFF2B241B),
          onPrimary: Colors.white,
          accent: Color(0xFFD6AC5C),
          accentLight: Color(0xFFEFD090),
          background: Color(0xFF14120F),
          surface: Color(0xFF1C1915),
          card: Color(0xFF24201A),
          cardElevated: Color(0xFF2E2820),
          border: Color(0xFF3A3228),
          textPrimary: Color(0xFFF4EFE6),
          textSecondary: Color(0xFFB9AC99),
          iqamah: Color(0xFF67D4EA),
          iqamahContainer: Color(0xFF11353E),
          success: Color(0xFF6EE7B7),
          sunrise: Color(0xFFFBBF24),
          dhikrContainerBg: Color(0xFF24201A),
          dhikrContainerBorder: Color(0xFF3A3228),
          quranParchmentBg: Color(0xFF262118),
          quranParchmentBorder: Color(0xFF3E3526),
          virtueBg: Color(0xFF1B1813),
          virtueBorder: Color(0xFF332C22),
          completedCardBg: Color(0xFF18261A),
          completedCardBorder: Color(0xFF36603C),
          navActiveBg: Color(0xFF2E261C),
        );

      case AppColorPalette.midnightSapphire:
        if (!dark) {
          return const WirdPalette(
            id: AppColorPalette.midnightSapphire,
            isDark: false,
            primary: Color(0xFF1B4980),
            primaryLight: Color(0xFF2C64A8),
            primaryContainer: Color(0xFFE6EFF9),
            onPrimary: Colors.white,
            accent: Color(0xFFC2962E),
            accentLight: Color(0xFFE6C56A),
            background: Color(0xFFF7FAFE),
            surface: Color(0xFFFFFFFF),
            card: Color(0xFFFFFFFF),
            cardElevated: Color(0xFFEBF2FA),
            border: Color(0xFFE1E8F2),
            textPrimary: Color(0xFF132238),
            textSecondary: Color(0xFF50637D),
            iqamah: Color(0xFF0E7490),
            iqamahContainer: Color(0xFFE6F4F7),
            success: Color(0xFF15803D),
            sunrise: Color(0xFFB45309),
            dhikrContainerBg: Color(0xFFF5F8FC),
            dhikrContainerBorder: Color(0xFFE2E9F3),
            quranParchmentBg: Color(0xFFFAF8F2),
            quranParchmentBorder: Color(0xFFE8E1CF),
            virtueBg: Color(0xFFF0F4FA),
            virtueBorder: Color(0xFFDCE4F2),
            completedCardBg: Color(0xFFE8F4EE),
            completedCardBorder: Color(0xFF83BBA0),
            navActiveBg: Color(0xFFE6EFF9),
          );
        }
        return const WirdPalette(
          id: AppColorPalette.midnightSapphire,
          isDark: true,
          primary: Color(0xFF30609B),
          primaryLight: Color(0xFF477EC0),
          primaryContainer: Color(0xFF182840),
          onPrimary: Colors.white,
          accent: Color(0xFFD6AE4F),
          accentLight: Color(0xFFF0D58B),
          background: Color(0xFF0B111A),
          surface: Color(0xFF121B29),
          card: Color(0xFF182436),
          cardElevated: Color(0xFF1F2F47),
          border: Color(0xFF283B57),
          textPrimary: Color(0xFFEEF3FA),
          textSecondary: Color(0xFF9DB0CA),
          iqamah: Color(0xFF67D4EA),
          iqamahContainer: Color(0xFF11353E),
          success: Color(0xFF4ADE80),
          sunrise: Color(0xFFFBBF24),
          dhikrContainerBg: Color(0xFF182436),
          dhikrContainerBorder: Color(0xFF283B57),
          quranParchmentBg: Color(0xFF1A2434),
          quranParchmentBorder: Color(0xFF2E3F5A),
          virtueBg: Color(0xFF111B2B),
          virtueBorder: Color(0xFF233550),
          completedCardBg: Color(0xFF112A24),
          completedCardBorder: Color(0xFF276B59),
          navActiveBg: Color(0xFF1C2F4C),
        );

      case AppColorPalette.amoledGold:
        return const WirdPalette(
          id: AppColorPalette.amoledGold,
          isDark: true,
          primary: Color(0xFF2B7A5E),
          primaryLight: Color(0xFF44997A),
          primaryContainer: Color(0xFF14241D),
          onPrimary: Colors.white,
          accent: Color(0xFFD8B355),
          accentLight: Color(0xFFF2D78B),
          background: Color(0xFF000000),
          surface: Color(0xFF0D0E0D),
          card: Color(0xFF141615),
          cardElevated: Color(0xFF1D201E),
          border: Color(0xFF262A28),
          textPrimary: Color(0xFFF4F3EE),
          textSecondary: Color(0xFFA6A9A4),
          iqamah: Color(0xFF67D4EA),
          iqamahContainer: Color(0xFF0E2B33),
          success: Color(0xFF4ADE80),
          sunrise: Color(0xFFFBBF24),
          dhikrContainerBg: Color(0xFF141615),
          dhikrContainerBorder: Color(0xFF262A28),
          quranParchmentBg: Color(0xFF171610),
          quranParchmentBorder: Color(0xFF2E2A1E),
          virtueBg: Color(0xFF0E100F),
          virtueBorder: Color(0xFF232724),
          completedCardBg: Color(0xFF0B2016),
          completedCardBorder: Color(0xFF215B3E),
          navActiveBg: Color(0xFF19241E),
        );
    }
  }

  @override
  WirdPalette copyWith({
    AppColorPalette? id,
    bool? isDark,
    Color? primary,
    Color? primaryLight,
    Color? primaryContainer,
    Color? onPrimary,
    Color? accent,
    Color? accentLight,
    Color? background,
    Color? surface,
    Color? card,
    Color? cardElevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? iqamah,
    Color? iqamahContainer,
    Color? success,
    Color? sunrise,
    Color? dhikrContainerBg,
    Color? dhikrContainerBorder,
    Color? quranParchmentBg,
    Color? quranParchmentBorder,
    Color? virtueBg,
    Color? virtueBorder,
    Color? completedCardBg,
    Color? completedCardBorder,
    Color? navActiveBg,
  }) {
    return WirdPalette(
      id: id ?? this.id,
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardElevated: cardElevated ?? this.cardElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      iqamah: iqamah ?? this.iqamah,
      iqamahContainer: iqamahContainer ?? this.iqamahContainer,
      success: success ?? this.success,
      sunrise: sunrise ?? this.sunrise,
      dhikrContainerBg: dhikrContainerBg ?? this.dhikrContainerBg,
      dhikrContainerBorder: dhikrContainerBorder ?? this.dhikrContainerBorder,
      quranParchmentBg: quranParchmentBg ?? this.quranParchmentBg,
      quranParchmentBorder: quranParchmentBorder ?? this.quranParchmentBorder,
      virtueBg: virtueBg ?? this.virtueBg,
      virtueBorder: virtueBorder ?? this.virtueBorder,
      completedCardBg: completedCardBg ?? this.completedCardBg,
      completedCardBorder: completedCardBorder ?? this.completedCardBorder,
      navActiveBg: navActiveBg ?? this.navActiveBg,
    );
  }

  @override
  WirdPalette lerp(ThemeExtension<WirdPalette>? other, double t) {
    if (other is! WirdPalette) return this;
    return WirdPalette(
      id: t < 0.5 ? id : other.id,
      isDark: t < 0.5 ? isDark : other.isDark,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t) ?? primaryLight,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t) ?? primaryContainer,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t) ?? onPrimary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentLight: Color.lerp(accentLight, other.accentLight, t) ?? accentLight,
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      card: Color.lerp(card, other.card, t) ?? card,
      cardElevated: Color.lerp(cardElevated, other.cardElevated, t) ?? cardElevated,
      border: Color.lerp(border, other.border, t) ?? border,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      iqamah: Color.lerp(iqamah, other.iqamah, t) ?? iqamah,
      iqamahContainer:
          Color.lerp(iqamahContainer, other.iqamahContainer, t) ?? iqamahContainer,
      success: Color.lerp(success, other.success, t) ?? success,
      sunrise: Color.lerp(sunrise, other.sunrise, t) ?? sunrise,
      dhikrContainerBg:
          Color.lerp(dhikrContainerBg, other.dhikrContainerBg, t) ?? dhikrContainerBg,
      dhikrContainerBorder:
          Color.lerp(dhikrContainerBorder, other.dhikrContainerBorder, t) ??
              dhikrContainerBorder,
      quranParchmentBg:
          Color.lerp(quranParchmentBg, other.quranParchmentBg, t) ?? quranParchmentBg,
      quranParchmentBorder:
          Color.lerp(quranParchmentBorder, other.quranParchmentBorder, t) ??
              quranParchmentBorder,
      virtueBg: Color.lerp(virtueBg, other.virtueBg, t) ?? virtueBg,
      virtueBorder: Color.lerp(virtueBorder, other.virtueBorder, t) ?? virtueBorder,
      completedCardBg:
          Color.lerp(completedCardBg, other.completedCardBg, t) ?? completedCardBg,
      completedCardBorder:
          Color.lerp(completedCardBorder, other.completedCardBorder, t) ??
              completedCardBorder,
      navActiveBg: Color.lerp(navActiveBg, other.navActiveBg, t) ?? navActiveBg,
    );
  }
}

extension WirdThemeContext on BuildContext {
  WirdPalette get palette =>
      Theme.of(this).extension<WirdPalette>() ??
      WirdPalette.of(AppColorPalette.goldenMushaf, Theme.of(this).brightness);
}
