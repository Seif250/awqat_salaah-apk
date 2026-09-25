import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/surah_model.dart';

class SurahCard extends StatelessWidget {
  final SurahModel surah;
  final VoidCallback onTap;

  const SurahCard({
    super.key,
    required this.surah,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Surah Number - Simple, subtle information container
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF0F4F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.6)
                            : AppColors.lightBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        toArabicDigits(surah.id),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Surah Name & Metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'سورة ${surah.name}',
                          style: TextStyle(
                            fontFamily: 'UthmanicHafs',
                            fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                            fontWeight: FontWeight.bold,
                            fontSize: 17.5,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            // Subtle semantic revelation badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: surah.isMeccan
                                    ? (isDark
                                        ? Colors.amber.withValues(alpha: 0.12)
                                        : const Color(0xFFFFF8E7))
                                    : (isDark
                                        ? Colors.teal.withValues(alpha: 0.12)
                                        : const Color(0xFFE8F5E9)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                surah.type,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: surah.isMeccan
                                      ? (isDark ? const Color(0xFFFFD54F) : const Color(0xFFB78103))
                                      : (isDark ? const Color(0xFF80CBC4) : const Color(0xFF2E7D32)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${toArabicDigits(surah.totalVerses)} آيات • الجزء ${toArabicDigits(surah.juz)} • صفحة ${toArabicDigits(surah.startPage)}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Subtle Left Arrow / Navigation Cue
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark.withValues(alpha: 0.35)
                        : AppColors.textSecondaryLight.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.6,
              indent: 64,
              endIndent: 16,
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.4)
                  : AppColors.lightBorder.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
