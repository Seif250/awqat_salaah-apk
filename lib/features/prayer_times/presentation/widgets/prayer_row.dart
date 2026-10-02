import 'package:flutter/material.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_colors.dart';
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
      semanticDescription.write('، موعد الإقامة $iqamahTimeFormatted');
    }

    return Semantics(
      label: semanticDescription.toString(),
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? (isDark ? const Color(0xFF13281E) : const Color(0xFFEDF6F1))
              : Colors.transparent,
          border: isHighlighted
              ? Border(
                  right: BorderSide(
                    color: isInIqamahWindow
                        ? AppColors.iqamahActive
                        : const Color(0xFFD4AF37),
                    width: 3.5,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // RIGHT: Subtle Circular Icon Container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? (isInIqamahWindow
                        ? AppColors.iqamahActive.withValues(alpha: 0.18)
                        : (isDark ? AppColors.primary.withValues(alpha: 0.35) : const Color(0xFFD8ECE0)))
                    : (isSunrise
                        ? (isDark ? Colors.amber.withValues(alpha: 0.1) : const Color(0xFFFEF3C7))
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF2F4F2))),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getPrayerIcon(prayer.type),
                color: isInIqamahWindow
                    ? AppColors.iqamahActive
                    : (isHighlighted
                        ? (isDark ? AppColors.accentGoldLight : AppColors.primary)
                        : (isSunrise
                            ? const Color(0xFFD97706)
                            : (isDark ? Colors.white60 : const Color(0xFF6B7280)))),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),

            // CENTER / Primary: Prayer Name & Secondary Iqama Info
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
                              ? FontWeight.w800
                              : (isSunrise ? FontWeight.w600 : FontWeight.w700),
                          color: isHighlighted
                              ? (isDark ? Colors.white : const Color(0xFF163A29))
                              : (isSunrise
                                  ? (isDark ? Colors.white70 : const Color(0xFF374151))
                                  : (isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937))),
                        ),
                      ),
                      if (isInIqamahWindow) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.iqamahActive.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.iqamahActive.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
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
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF362B10)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'القادمة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
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
                        fontSize: 11.5,
                        color: isDark ? Colors.white38 : const Color(0xFF6B7280),
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
                        color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            // LEFT: Prayer Time (Scannable, Bold, Tabular figures)
            Text(
              formattedTime,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isHighlighted
                    ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF163A29))
                    : (isSunrise
                        ? (isDark ? Colors.white70 : const Color(0xFF4B5563))
                        : (isDark ? AppColors.textPrimaryDark : const Color(0xFF1F2937))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
