import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/prayer_day_model.dart';
import '../../data/models/prayer_time_model.dart';

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
    final now = DateTime.now();

    // Check if we are currently between an Adhan and its Iqamah
    final activeIqamahPrayer = prayerDay.activeIqamahPrayer(now);
    final isIqamahActive = activeIqamahPrayer != null;

    final nextPrayerModel = prayerDay.getPrayer(prayerDay.nextPrayerType);
    final nextPrayerName = prayerDay.nextPrayerType.nameArabic;
    final nextPrayerTimeFormatted = DateUtilsHelper.formatPrayerTime(
      prayerDay.nextPrayerTime,
      is24Hour: is24Hour,
    );

    final nextPrayerIqamahFormatted = nextPrayerModel?.iqamahTime != null
        ? DateUtilsHelper.formatPrayerTime(
            nextPrayerModel!.iqamahTime!,
            is24Hour: is24Hour,
          )
        : null;

    final countdownFormatted = isIqamahActive
        ? DateUtilsHelper.formatCountdown(
            activeIqamahPrayer.timeRemainingToIqamah(now) ?? Duration.zero)
        : DateUtilsHelper.formatCountdown(remainingDuration);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isIqamahActive
              ? [
                  const Color(0xFF1B4D3E),
                  const Color(0xFF0F382B),
                  const Color(0xFF0A261D),
                ]
              : (isDark
                  ? [
                      const Color(0xFF133626),
                      const Color(0xFF0D241A),
                      const Color(0xFF091710),
                    ]
                  : [
                      AppColors.primary,
                      const Color(0xFF12633E),
                      const Color(0xFF0A3D25),
                    ]),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isIqamahActive
              ? const Color(0xFF48CAE4).withOpacity(0.6)
              : AppColors.accentGold.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header: Icon + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isIqamahActive
                      ? const Color(0xFF48CAE4).withOpacity(0.2)
                      : AppColors.accentGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isIqamahActive
                        ? const Color(0xFF48CAE4).withOpacity(0.5)
                        : AppColors.accentGold.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getPrayerIcon(isIqamahActive
                      ? activeIqamahPrayer.type
                      : prayerDay.nextPrayerType),
                  color: isIqamahActive
                      ? const Color(0xFF90E0EF)
                      : AppColors.accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isIqamahActive ? 'حان وقت الصلاة (بين الأذان والإقامة)' : 'الصلاة القادمة',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isIqamahActive
                      ? const Color(0xFF90E0EF)
                      : AppColors.accentGoldLight,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Prayer Name
          Text(
            isIqamahActive
                ? activeIqamahPrayer.type.nameArabic
                : nextPrayerName,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 14),

          // Live Countdown Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isIqamahActive
                    ? const Color(0xFF48CAE4).withOpacity(0.3)
                    : Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIqamahActive ? Icons.access_alarms_rounded : Icons.timer_outlined,
                  color: isIqamahActive
                      ? const Color(0xFF90E0EF)
                      : AppColors.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isIqamahActive ? 'متبقي للإقامة: ' : 'متبقي للأذان: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  countdownFormatted,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isIqamahActive
                        ? const Color(0xFF90E0EF)
                        : AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Adhan & Iqamah Time Summary Footer
          if (isIqamahActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'الإقامة في: ${DateUtilsHelper.formatPrayerTime(activeIqamahPrayer.iqamahTime!, is24Hour: is24Hour)} (+${activeIqamahPrayer.iqamahOffsetMinutes} د)',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'الأذان: $nextPrayerTimeFormatted',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (nextPrayerIqamahFormatted != null &&
                    nextPrayerModel!.iqamahOffsetMinutes > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                  Text(
                    'الإقامة: $nextPrayerIqamahFormatted (+${nextPrayerModel.iqamahOffsetMinutes}د)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.accentGoldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
