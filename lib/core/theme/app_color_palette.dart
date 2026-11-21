import 'package:flutter/material.dart';

/// Selectable visual color palettes for Wird (3 core identities).
/// Preserves legacy storage keys safely via [fromStorageKey].
enum AppColorPalette {
  royalEmerald,
  goldenMushaf,
  amoledGold,
}

extension AppColorPaletteExtension on AppColorPalette {
  String get storageKey => name;

  static AppColorPalette fromStorageKey(String? key) {
    if (key == null) return AppColorPalette.royalEmerald;
    if (key == 'sepiaParchment') return AppColorPalette.goldenMushaf;
    if (key == 'midnightSapphire') return AppColorPalette.royalEmerald;
    return AppColorPalette.values.firstWhere(
      (p) => p.name == key,
      orElse: () => AppColorPalette.royalEmerald,
    );
  }

  String get titleArabic {
    switch (this) {
      case AppColorPalette.royalEmerald:
        return 'الزمردي النقي';
      case AppColorPalette.goldenMushaf:
        return 'المصحف الذهبي';
      case AppColorPalette.amoledGold:
        return 'الليلي الخالص (AMOLED)';
    }
  }

  String get subtitleArabic {
    switch (this) {
      case AppColorPalette.royalEmerald:
        return 'أبيض ناصع مع أخضر زمردي كلاسيكي واضح ومريح';
      case AppColorPalette.goldenMushaf:
        return 'ورق مصحفي دافئ مع أخضر عميق ولمسة ذهبية هادئة';
      case AppColorPalette.amoledGold:
        return 'أسود خالص لشاشات OLED وراحة تامة للعين ليلاً';
    }
  }

  /// Three swatch colors for visual theme picker previews: [canvas, primary, accent].
  List<Color> get previewColors {
    switch (this) {
      case AppColorPalette.royalEmerald:
        return const [Color(0xFFFFFFFF), Color(0xFF0F5E3B), Color(0xFFC5962C)];
      case AppColorPalette.goldenMushaf:
        return const [Color(0xFFFAF4E4), Color(0xFF1A5238), Color(0xFFB8860B)];
      case AppColorPalette.amoledGold:
        return const [Color(0xFF000000), Color(0xFF1D6E4E), Color(0xFFD8B355)];
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
            primary: Color(0xFF1A5238),
            primaryLight: Color(0xFF287250),
            primaryContainer: Color(0xFFEBE4CF),
            onPrimary: Colors.white,
            accent: Color(0xFFB8860B),
            accentLight: Color(0xFFE2BE5B),
            background: Color(0xFFFAF4E4),
            surface: Color(0xFFFFFDF7),
            card: Color(0xFFFFFDF7),
            cardElevated: Color(0xFFF3ECD9),
            border: Color(0xFFE4DAC1),
            textPrimary: Color(0xFF1E1910),
            textSecondary: Color(0xFF655A47),
            iqamah: Color(0xFF0E7490),
            iqamahContainer: Color(0xFFE6F4F7),
            success: Color(0xFF15803D),
            sunrise: Color(0xFFB45309),
            dhikrContainerBg: Color(0xFFFAF6EB),
            dhikrContainerBorder: Color(0xFFE6DEC8),
            quranParchmentBg: Color(0xFFFAF4E4),
            quranParchmentBorder: Color(0xFFE4DAC1),
            virtueBg: Color(0xFFF5EFE0),
            virtueBorder: Color(0xFFE2D8BE),
            completedCardBg: Color(0xFFEDF4E8),
            completedCardBorder: Color(0xFF99BA8F),
            navActiveBg: Color(0xFFEBE4CF),
          );
        }
        return const WirdPalette(
          id: AppColorPalette.goldenMushaf,
          isDark: true,
          primary: Color(0xFF2A7354),
          primaryLight: Color(0xFF429472),
          primaryContainer: Color(0xFF252118),
          onPrimary: Colors.white,
          accent: Color(0xFFD9B254),
          accentLight: Color(0xFFEFD386),
          background: Color(0xFF13110D),
          surface: Color(0xFF1C1913),
          card: Color(0xFF231F18),
          cardElevated: Color(0xFF2C271F),
          border: Color(0xFF393227),
          textPrimary: Color(0xFFF5F0E4),
          textSecondary: Color(0xFFB6AC97),
          iqamah: Color(0xFF67D4EA),
          iqamahContainer: Color(0xFF11353E),
          success: Color(0xFF4ADE80),
          sunrise: Color(0xFFFBBF24),
          dhikrContainerBg: Color(0xFF231F18),
          dhikrContainerBorder: Color(0xFF393227),
          quranParchmentBg: Color(0xFF252017),
          quranParchmentBorder: Color(0xFF3D3424),
          virtueBg: Color(0xFF1B1812),
          virtueBorder: Color(0xFF332D22),
          completedCardBg: Color(0xFF17261B),
          completedCardBorder: Color(0xFF336243),
          navActiveBg: Color(0xFF2A241A),
        );

      case AppColorPalette.royalEmerald:
        if (!dark) {
          return const WirdPalette(
            id: AppColorPalette.royalEmerald,
            isDark: false,
            primary: Color(0xFF0F5E3B),
            primaryLight: Color(0xFF1D7A51),
            primaryContainer: Color(0xFFE7F4EE),
            onPrimary: Colors.white,
            accent: Color(0xFFC5962C),
            accentLight: Color(0xFFE7C770),
            background: Color(0xFFFFFFFF),
            surface: Color(0xFFFFFFFF),
            card: Color(0xFFFFFFFF),
            cardElevated: Color(0xFFF3F8F5),
            border: Color(0xFFDFE9E3),
            textPrimary: Color(0xFF102219),
            textSecondary: Color(0xFF53665C),
            iqamah: Color(0xFF0E7490),
            iqamahContainer: Color(0xFFE6F4F7),
            success: Color(0xFF15803D),
            sunrise: Color(0xFFB45309),
            dhikrContainerBg: Color(0xFFF8FBF9),
            dhikrContainerBorder: Color(0xFFE2ECE6),
            quranParchmentBg: Color(0xFFF9FBF9),
            quranParchmentBorder: Color(0xFFE2EBE5),
            virtueBg: Color(0xFFF4F8F6),
            virtueBorder: Color(0xFFDFEAE3),
            completedCardBg: Color(0xFFEAF5EE),
            completedCardBorder: Color(0xFF8EC0A3),
            navActiveBg: Color(0xFFE7F4EE),
          );
        }
        return const WirdPalette(
          id: AppColorPalette.royalEmerald,
          isDark: true,
          primary: Color(0xFF22734E),
          primaryLight: Color(0xFF379268),
          primaryContainer: Color(0xFF153124),
          onPrimary: Colors.white,
          accent: Color(0xFFD4AF37),
          accentLight: Color(0xFFF1D788),
          background: Color(0xFF0B1410),
          surface: Color(0xFF121F19),
          card: Color(0xFF172820),
          cardElevated: Color(0xFF1F352B),
          border: Color(0xFF2A4236),
          textPrimary: Color(0xFFEFF6F2),
          textSecondary: Color(0xFFA0B8AD),
          iqamah: Color(0xFF67D4EA),
          iqamahContainer: Color(0xFF11353E),
          success: Color(0xFF4ADE80),
          sunrise: Color(0xFFFBBF24),
          dhikrContainerBg: Color(0xFF172820),
          dhikrContainerBorder: Color(0xFF2A4236),
          quranParchmentBg: Color(0xFF1B2821),
          quranParchmentBorder: Color(0xFF2E4337),
          virtueBg: Color(0xFF12201A),
          virtueBorder: Color(0xFF253B30),
          completedCardBg: Color(0xFF112C1F),
          completedCardBorder: Color(0xFF276649),
          navActiveBg: Color(0xFF173628),
        );

      case AppColorPalette.amoledGold:
        return const WirdPalette(
          id: AppColorPalette.amoledGold,
          isDark: true,
          primary: Color(0xFF1D6E4E),
          primaryLight: Color(0xFF38906D),
          primaryContainer: Color(0xFF12221B),
          onPrimary: Colors.white,
          accent: Color(0xFFD8B355),
          accentLight: Color(0xFFF2D78B),
          background: Color(0xFF000000),
          surface: Color(0xFF0C0D0C),
          card: Color(0xFF131514),
          cardElevated: Color(0xFF1C201E),
          border: Color(0xFF252927),
          textPrimary: Color(0xFFF4F3EE),
          textSecondary: Color(0xFFA6A9A4),
          iqamah: Color(0xFF67D4EA),
          iqamahContainer: Color(0xFF0E2B33),
          success: Color(0xFF4ADE80),
          sunrise: Color(0xFFFBBF24),
          dhikrContainerBg: Color(0xFF131514),
          dhikrContainerBorder: Color(0xFF252927),
          quranParchmentBg: Color(0xFF161510),
          quranParchmentBorder: Color(0xFF2D291D),
          virtueBg: Color(0xFF0E100F),
          virtueBorder: Color(0xFF222623),
          completedCardBg: Color(0xFF0B2016),
          completedCardBorder: Color(0xFF215B3E),
          navActiveBg: Color(0xFF17231D),
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
      WirdPalette.of(AppColorPalette.royalEmerald, Theme.of(this).brightness);
}
