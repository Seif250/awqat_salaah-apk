import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/surah_model.dart';

class JuzListView extends StatelessWidget {
  final List<SurahModel> surahs;
  final void Function(SurahModel surah, int targetAyah) onJuzSelected;

  const JuzListView({
    super.key,
    required this.surahs,
    required this.onJuzSelected,
  });

  static const List<String> juzNames = [
    'الم',
    'سيقول السفهاء',
    'تلك الرسل',
    'لن تنالوا البر',
    'والمحصنات',
    'لا يحب الله',
    'وإذا سمعوا',
    'ولو أننا',
    'قال الملأ',
    'واعلموا',
    'يعتذرون إليكم',
    'وما من دابة',
    'وما أبرئ نفسي',
    'ربما يود الذين كفروا',
    'سبحان الذي أسرى',
    'قال ألم أقل لك',
    'اقترب للناس',
    'قد أفلح المؤمنون',
    'وقال الذين لا يرجون',
    'أمن خلق',
    'اتل ما أوحي إليك',
    'ومن يقنت',
    'وما لي لا أعبد',
    'فمن أظلم',
    'إليه يرد علم الساعة',
    'حم',
    'قال فما خطبكم',
    'قد سمع الله',
    'تبارك الذي',
    'عم يتساءلون',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 88),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        final juzTitle = index < juzNames.length ? juzNames[index] : '';

        SurahModel? targetSurah;
        int targetAyah = 1;
        int startPage = 1;

        for (final s in surahs) {
          final firstMatchingAyah = s.verses.where((v) => v.juz == juzNumber).firstOrNull;
          if (firstMatchingAyah != null) {
            targetSurah = s;
            targetAyah = firstMatchingAyah.id;
            startPage = firstMatchingAyah.page;
            break;
          }
        }

        // Count how many hizbs are in this juz (always 2)
        final hizbStart = (juzNumber - 1) * 2 + 1;
        final hizbEnd = juzNumber * 2;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (targetSurah != null) {
                onJuzSelected(targetSurah, targetAyah);
              }
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Juz Number - Subtle information container
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
                            toArabicDigits(juzNumber),
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

                      // Juz Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'الجزء ${toArabicDigits(juzNumber)}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                if (juzTitle.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textSecondaryDark.withValues(alpha: 0.4)
                                            : AppColors.textSecondaryLight.withValues(alpha: 0.4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      juzTitle,
                                      style: TextStyle(
                                        fontFamily: 'UthmanicHafs',
                                        fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.accentGoldLight
                                            : AppColors.primary,
                                        height: 1.25,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (targetSurah != null) ...[
                                  Text(
                                    'سورة ${targetSurah.name}',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  Text(
                                    ' • ص ${toArabicDigits(startPage)}',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11.5,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                                Text(
                                  ' • الحزب ${toArabicDigits(hizbStart)}-${toArabicDigits(hizbEnd)}',
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

                      // Navigation cue
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
      },
    );
  }
}
