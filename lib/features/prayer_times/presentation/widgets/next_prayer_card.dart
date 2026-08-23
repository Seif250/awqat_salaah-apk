import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/prayer_day_model.dart';

class NextPrayerCard extends StatelessWidget {
  final PrayerDayModel prayerDay;
  final Duration remainingDuration;
  final bool is24Hour;

  const NextPrayerCard({
    super.key,
    required this.prayerDay,
    required this.remainingDuration,
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
    final nextPrayerName = prayerDay.nextPrayerType.nameArabic;
    final nextPrayerTimeFormatted = DateUtilsHelper.formatPrayerTime(
      prayerDay.nextPrayerTime,
      is24Hour: is24Hour,
    );
    final countdownFormatted = DateUtilsHelper.formatCountdown(remainingDuration);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF133626),
                  const Color(0xFF0D241A),
                  const Color(0xFF091710),
                ]
              : [
                  AppColors.primary,
                  const Color(0xFF12633E),
                  const Color(0xFF0A3D25),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.accentGold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header: Icon + "الصلاة القادمة"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getPrayerIcon(prayerDay.nextPrayerType),
                  color: AppColors.accentGold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'الصلاة القادمة',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.accentGoldLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Next Prayer Name
          Text(
            nextPrayerName,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 38,
            ),
          ),
          const SizedBox(height: 16),

          // Live Countdown Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AppColors.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'متبقي: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  countdownFormatted,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Prayer exact time
          Text(
            'اليوم في $nextPrayerTimeFormatted',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
