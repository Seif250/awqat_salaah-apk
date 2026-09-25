import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/prayer_time_model.dart';

class PrayerRow extends StatelessWidget {
  final PrayerTimeModel prayer;
  final bool is24Hour;
  final bool isFirst;
  final bool isLast;

  const PrayerRow({
    super.key,
    required this.prayer,
    required this.is24Hour,
    this.isFirst = false,
    this.isLast = false,
  });

  IconData _getPrayerIcon(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return Icons.nights_stay_outlined;
      case PrayerType.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerType.dhuhr:
        return Icons.light_mode_outlined;
      case PrayerType.asr:
        return Icons.wb_twilight_outlined;
      case PrayerType.maghrib:
        return Icons.nightlight_outlined;
      case PrayerType.isha:
        return Icons.bedtime_outlined;
      case PrayerType.none:
        return Icons.access_time_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isInIqamahWindow = prayer.isCurrentlyInIqamahWindow(now);
    final isSunrise = prayer.type == PrayerType.sunrise;

    final formattedTime = DateUtilsHelper.formatPrayerTime(
      prayer.time,
      is24Hour: is24Hour,
    );

    final iqamahTimeFormatted = prayer.iqamahTime != null && prayer.iqamahOffsetMinutes > 0
        ? DateUtilsHelper.formatPrayerTime(
            prayer.iqamahTime!,
            is24Hour: is24Hour,
          )
        : null;

    final isHighlighted = prayer.isNext || prayer.isCurrent || isInIqamahWindow;

    final semanticDescription = StringBuffer(prayer.type.nameArabic)
      ..write('، وقت الأذان $formattedTime');
    if (iqamahTimeFormatted != null) {
      semanticDescription.write('، موعد الإقامة $iqamahTimeFormatted، بعد ${prayer.iqamahOffsetMinutes} دقائق');
    }
    if (isInIqamahWindow) {
      semanticDescription.write('، أُذّن الآن، بانتظار الإقامة');
    } else if (prayer.isNext) {
      semanticDescription.write('، هي الصلاة القادمة');
    }

    return Semantics(
      label: semanticDescription.toString(),
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? (isDark ? const Color(0xFF13281E) : const Color(0xFFF0F7F3))
              : Colors.transparent,
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          border: isHighlighted
              ? Border(
                  right: BorderSide(
                    color: isInIqamahWindow
                        ? AppColors.iqamahActive
                        : AppColors.accentGold,
                    width: 3.5,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // RIGHT: Subtle Icon Container
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? (isInIqamahWindow
                        ? AppColors.iqamahActive.withValues(alpha: 0.18)
                        : (isDark ? AppColors.primary.withValues(alpha: 0.3) : const Color(0xFFD1E7DD)))
                    : (isSunrise
                        ? (isDark ? Colors.amber.withValues(alpha: 0.1) : const Color(0xFFFFFBEB))
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF4F6F4))),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getPrayerIcon(prayer.type),
                color: isInIqamahWindow
                    ? AppColors.iqamahActive
                    : (isHighlighted
                        ? AppColors.primary
                        : (isSunrise
                            ? const Color(0xFFD97706)
                            : (isDark ? Colors.white60 : const Color(0xFF6B7280)))),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),

            // CENTER / Primary: Prayer Name & Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        prayer.type.nameArabic,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15.5,
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : (isSunrise ? FontWeight.w500 : FontWeight.w600),
                          color: isHighlighted
                              ? (isDark ? AppColors.accentGoldLight : AppColors.primaryDark)
                              : (isSunrise
                                  ? (isDark ? Colors.white70 : const Color(0xFF4B5563))
                                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        ),
                      ),
                      if (isInIqamahWindow) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.iqamahActive.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.iqamahActive.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'أُذِّن الآن',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.iqamahActive,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ] else if (prayer.isNext) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.accentGold.withValues(alpha: 0.2)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.accentGold.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'القادمة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: isDark ? AppColors.accentGoldLight : const Color(0xFF92400E),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Metadata Subtitle: Adhan and Iqama
                  if (isSunrise)
                    Text(
                      'شروق الشمس',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
                      ),
                    )
                  else
                    Text(
                      iqamahTimeFormatted != null && prayer.iqamahOffsetMinutes > 0
                          ? 'الأذان $formattedTime  •  الإقامة $iqamahTimeFormatted'
                          : 'الأذان $formattedTime',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),

            // LEFT: Prayer Time (Scannable, Tabular Figures)
            Text(
              formattedTime,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isHighlighted
                    ? (isDark ? AppColors.accentGold : AppColors.primary)
                    : (isSunrise
                        ? (isDark ? Colors.white70 : const Color(0xFF6B7280))
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
