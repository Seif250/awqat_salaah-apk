import 'dart:ui';
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
    final isDuringIqamah = prayerDay.phase == PrayerPhase.duringIqamah;

    final focusedPrayerModel = prayerDay.getPrayer(prayerDay.focusPrayerType);
    final focusedPrayerName = prayerDay.focusPrayerType.nameArabic;

    final focusedPrayerTimeFormatted = focusedPrayerModel != null
        ? DateUtilsHelper.formatPrayerTime(
            focusedPrayerModel.time,
            is24Hour: is24Hour,
          )
        : '--:--';

    final focusedPrayerIqamahFormatted = focusedPrayerModel?.iqamahTime != null
        ? DateUtilsHelper.formatPrayerTime(
            focusedPrayerModel!.iqamahTime!,
            is24Hour: is24Hour,
          )
        : null;

    final countdownFormatted = DateUtilsHelper.formatCountdown(remainingDuration);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDuringIqamah
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
          color: isDuringIqamah
              ? const Color(0xFF48CAE4).withOpacity(0.7)
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
                  color: isDuringIqamah
                      ? const Color(0xFF48CAE4).withOpacity(0.2)
                      : AppColors.accentGold.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDuringIqamah
                        ? const Color(0xFF48CAE4).withOpacity(0.5)
                        : AppColors.accentGold.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getPrayerIcon(prayerDay.focusPrayerType),
                  color: isDuringIqamah
                      ? const Color(0xFF90E0EF)
                      : AppColors.accentGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isDuringIqamah ? 'أُذِّن الآن للصلاة (انتظار الإقامة)' : 'الصلاة القادمة',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDuringIqamah
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
            focusedPrayerName,
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
                color: isDuringIqamah
                    ? const Color(0xFF48CAE4).withOpacity(0.4)
                    : Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDuringIqamah ? Icons.access_alarms_rounded : Icons.timer_outlined,
                  color: isDuringIqamah
                      ? const Color(0xFF90E0EF)
                      : AppColors.accentGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isDuringIqamah ? 'متبقي للإقامة: ' : 'متبقي للأذان: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  countdownFormatted,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: isDuringIqamah
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

          // Footer info
          if (isDuringIqamah && focusedPrayerIqamahFormatted != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'موعد الإقامة في $focusedPrayerIqamahFormatted (+${focusedPrayerModel!.iqamahOffsetMinutes} د)',
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
                  'الأذان: $focusedPrayerTimeFormatted',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (focusedPrayerIqamahFormatted != null &&
                    focusedPrayerModel!.iqamahOffsetMinutes > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ),
                  Text(
                    'الإقامة: $focusedPrayerIqamahFormatted (+${focusedPrayerModel.iqamahOffsetMinutes}د)',
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
