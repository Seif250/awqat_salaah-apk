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
    final formattedTime = DateUtilsHelper.formatPrayerTime(
      prayer.time,
      is24Hour: is24Hour,
    );

    // Active (Current) or Next styling
    final isHighlighted = prayer.isNext || prayer.isCurrent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark
                ? AppColors.darkCardElevated
                : AppColors.lightCardElevated)
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: prayer.isNext
              ? AppColors.accentGold
              : (isHighlighted
                  ? AppColors.primaryLight.withOpacity(0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          width: prayer.isNext ? 1.5 : 1,
        ),
        boxShadow: prayer.isNext
            ? [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.15),
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
                  ? (prayer.isNext
                      ? AppColors.accentGold.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.15))
                  : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPrayerIcon(prayer.type),
              color: prayer.isNext
                  ? AppColors.accentGold
                  : (isHighlighted
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : Colors.black54)),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Prayer Name + Status Badge
          Expanded(
            child: Row(
              children: [
                Text(
                  prayer.type.nameArabic,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                    color: prayer.isNext
                        ? (isDark ? AppColors.accentGoldLight : AppColors.primaryDark)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
                if (prayer.isNext) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
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
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Prayer Time
          Text(
            formattedTime,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: prayer.isNext
                  ? (isDark ? AppColors.accentGold : AppColors.primary)
                  : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
