import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';

class QuranSettingsSheet extends StatelessWidget {
  final double currentFontSize;
  final bool isContinuousMode;
  final bool isTajweedMode;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<bool> onContinuousModeChanged;
  final ValueChanged<bool>? onTajweedModeChanged;

  const QuranSettingsSheet({
    super.key,
    required this.currentFontSize,
    required this.isContinuousMode,
    this.isTajweedMode = false,
    required this.onFontSizeChanged,
    required this.onContinuousModeChanged,
    this.onTajweedModeChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required double currentFontSize,
    required bool isContinuousMode,
    bool isTajweedMode = false,
    required ValueChanged<double> onFontSizeChanged,
    required ValueChanged<bool> onContinuousModeChanged,
    ValueChanged<bool>? onTajweedModeChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuranSettingsSheet(
        currentFontSize: currentFontSize,
        isContinuousMode: isContinuousMode,
        isTajweedMode: isTajweedMode,
        onFontSizeChanged: onFontSizeChanged,
        onContinuousModeChanged: onContinuousModeChanged,
        onTajweedModeChanged: onTajweedModeChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: AppColors.accentGold, size: 22),
                const SizedBox(width: 10),
                Text(
                  'خيارات القراءة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Font size title & value
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حجم الخط',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  toArabicDigits(currentFontSize.round()),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Font size slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accentGold,
                inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                thumbColor: AppColors.accentGold,
                overlayColor: AppColors.accentGold.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: currentFontSize,
                min: 16.0,
                max: 36.0,
                divisions: 10,
                onChanged: onFontSizeChanged,
              ),
            ),

            // Preview Text Box
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Center(
                child: Text(
                  'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                    fontSize: currentFontSize,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Reading mode toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نمط المصحف المتصل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      Text(
                        isContinuousMode
                            ? 'نص متصل مع أرقام الآيات'
                            : 'بطاقات منفصلة لكل آية',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isContinuousMode,
                    activeThumbColor: AppColors.accentGold,
                    activeTrackColor: AppColors.primary,
                    onChanged: onContinuousModeChanged,
                  ),
                ],
              ),
            ),
            if (onTajweedModeChanged != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ألوان التجويد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          isTajweedMode
                              ? 'إظهار أحكام التجويد بألوان مصحف التجويد'
                              : 'المصحف العادي باللون الأحادي',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isTajweedMode,
                      activeThumbColor: AppColors.accentGold,
                      activeTrackColor: AppColors.primary,
                      onChanged: onTajweedModeChanged,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
