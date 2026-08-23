import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/prayer_time_model.dart';

class PrayerRow extends StatelessWidget {
  final PrayerTimeModel prayer;
  final bool is24Hour;

  const PrayerRow({
    super.key,
    required this.prayer,
    required this.is24Hour,
  });

  IconData _getPrayerIcon(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return Icons.nights_stay_rounded;
      case PrayerType.sunrise:
        return Icons.wb_sunny_rounded;
      case PrayerType.dhuhr:
        return Icons.light_mode_rounded;
      case PrayerType.asr:
        return Icons.wb_twilight_rounded;
      case PrayerType.maghrib:
        return Icons.nightlight_round;
      case PrayerType.isha:
        return Icons.bedtime_rounded;
      case PrayerType.none:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final isInIqamahWindow = prayer.isCurrentlyInIqamahWindow(now);

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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark
                ? AppColors.darkCardElevated
                : AppColors.lightCardElevated)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isInIqamahWindow
              ? const Color(0xFF48CAE4)
              : (prayer.isNext
                  ? AppColors.accentGold
                  : (isHighlighted
                      ? AppColors.primaryLight.withOpacity(0.4)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder))),
          width: (prayer.isNext || isInIqamahWindow) ? 1.5 : 1,
        ),
        boxShadow: (prayer.isNext || isInIqamahWindow)
            ? [
                BoxShadow(
                  color: (isInIqamahWindow ? const Color(0xFF48CAE4) : AppColors.accentGold)
                      .withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? (isInIqamahWindow
                      ? const Color(0xFF48CAE4).withOpacity(0.2)
                      : (prayer.isNext
                          ? AppColors.accentGold.withOpacity(0.2)
                          : AppColors.primary.withOpacity(0.15)))
                  : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPrayerIcon(prayer.type),
              color: isInIqamahWindow
                  ? const Color(0xFF48CAE4)
                  : (prayer.isNext
                      ? AppColors.accentGold
                      : (isHighlighted
                          ? AppColors.primary
                          : (isDark ? Colors.white70 : Colors.black54))),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Prayer Name + Status Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      prayer.type.nameArabic,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                        color: isInIqamahWindow
                            ? (isDark ? const Color(0xFF90E0EF) : AppColors.primaryDark)
                            : (prayer.isNext
                                ? (isDark ? AppColors.accentGoldLight : AppColors.primaryDark)
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      ),
                    ),
                    if (isInIqamahWindow) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF48CAE4).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF48CAE4).withOpacity(0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'أُذِّن الآن',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF48CAE4),
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
                          color: AppColors.accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.accentGold.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'القادمة',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Times Column (Adhan + Iqamah)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Adhan Time
              Text(
                formattedTime,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isInIqamahWindow
                      ? const Color(0xFF48CAE4)
                      : (prayer.isNext
                          ? (isDark ? AppColors.accentGold : AppColors.primary)
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                ),
              ),

              // Iqamah Subtitle
              if (iqamahTimeFormatted != null) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'الإقامة: $iqamahTimeFormatted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.accentGold.withOpacity(0.12)
                            : AppColors.accentGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${prayer.iqamahOffsetMinutes}د',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.accentGoldLight
                              : AppColors.accentGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
