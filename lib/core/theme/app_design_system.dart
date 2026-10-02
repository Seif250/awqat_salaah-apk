import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Comprehensive 2026 Production-Ready Islamic Mobile App Design System.
/// Provides consistent design tokens, styling helpers, and geometry scales.
class AppDesignSystem {
  AppDesignSystem._();

  // ---------------------------------------------------------------------------
  // SPACING SCALE (8pt base system with half-steps)
  // ---------------------------------------------------------------------------
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;

  // ---------------------------------------------------------------------------
  // BORDER RADIUS SCALE
  // ---------------------------------------------------------------------------
  static const double radiusXs = 6.0;
  static const double radiusSm = 10.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 18.0;
  static const double radiusCard = 22.0;
  static const double radiusPill = 28.0;
  static const double radiusFull = 999.0;

  static const BorderRadius borderCard = BorderRadius.all(Radius.circular(radiusCard));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(radiusPill));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(radiusSm));

  // ---------------------------------------------------------------------------
  // SOFT SHADOWS (Subtle, modern, no harsh black borders)
  // ---------------------------------------------------------------------------
  static List<BoxShadow> cardShadow({bool isDark = false}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.035),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 3),
        ),
      ];

  static List<BoxShadow> heroShadow({bool isDark = false}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.08),
          blurRadius: 14,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> navBarShadow({bool isDark = false}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, -3),
        ),
      ];

  // ---------------------------------------------------------------------------
  // REUSABLE CARD & CONTAINER DECORATIONS
  // ---------------------------------------------------------------------------

  /// Main Dhikr Card surface decoration
  static BoxDecoration cardDecoration({
    required bool isDark,
    bool isCompleted = false,
  }) {
    return BoxDecoration(
      color: isCompleted
          ? (isDark ? const Color(0xFF103324) : const Color(0xFFE5F0EA))
          : (isDark ? AppColors.darkCard : AppColors.lightCard),
      borderRadius: borderCard,
      border: Border.all(
        color: isCompleted
            ? (isDark ? const Color(0xFF246C4E) : const Color(0xFF8DC0A7))
            : (isDark ? AppColors.darkBorder : const Color(0xFFEFF2F0)),
        width: isCompleted ? 1.4 : 1.0,
      ),
      boxShadow: cardShadow(isDark: isDark),
    );
  }

  /// Tinted container for the main Arabic Quran / Dhikr text
  static BoxDecoration dhikrTextContainerDecoration({
    required bool isDark,
    bool isWarmParchment = false,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : (isWarmParchment ? const Color(0xFFFFF9ED) : const Color(0xFFF7FAF8)),
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : (isWarmParchment ? const Color(0xFFF5EEDB) : const Color(0xFFEBF1ED)),
        width: 0.8,
      ),
    );
  }

  /// Subtle sage container for "من فضلها" virtue box
  static BoxDecoration virtueBoxDecoration({required bool isDark}) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF13281E) : AppColors.sageLight,
      borderRadius: BorderRadius.circular(radiusSm + 2),
      border: Border.all(
        color: isDark ? AppColors.darkBorder : AppColors.sageBorder.withValues(alpha: 0.7),
        width: 0.7,
      ),
    );
  }

  /// Pill button decoration (for active category, bookmark "حفظ", counters)
  static BoxDecoration pillTabDecoration({
    required bool isSelected,
    required bool isDark,
  }) {
    if (isSelected) {
      return BoxDecoration(
        color: AppColors.primary,
        borderRadius: borderPill,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: borderPill,
      border: Border.all(
        color: isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB),
        width: 0.9,
      ),
    );
  }

  /// Bookmark "حفظ" button decoration
  static BoxDecoration bookmarkButtonDecoration({
    required bool isSaved,
    required bool isDark,
  }) {
    return BoxDecoration(
      color: isSaved
          ? (isDark ? AppColors.primary.withValues(alpha: 0.3) : AppColors.sageMedium)
          : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF2F6F3)),
      borderRadius: BorderRadius.circular(radiusSm + 2),
      border: Border.all(
        color: isSaved
            ? AppColors.primary.withValues(alpha: 0.5)
            : (isDark ? Colors.white12 : const Color(0xFFDFE9E2)),
        width: 0.8,
      ),
    );
  }
}
