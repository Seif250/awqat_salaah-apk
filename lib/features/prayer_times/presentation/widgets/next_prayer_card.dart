import 'package:flutter/material.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_colors.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDuringIqamah
              ? [
                  const Color(0xFF1B4D3E),
                  const Color(0xFF10362A),
                  const Color(0xFF092018),
                ]
              : (isDark
                  ? [
                      const Color(0xFF193D2C),
                      const Color(0xFF10281D),
                      const Color(0xFF0A1912),
                    ]
                  : [
                      AppColors.primary,
                      const Color(0xFF125C3A),
                      const Color(0xFF0A3D25),
                    ]),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDuringIqamah
              ? const Color(0xFF48CAE4).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Top Label Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDuringIqamah
                  ? const Color(0xFF48CAE4).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPrayerIcon(prayerDay.focusPrayerType),
                  color: isDuringIqamah ? const Color(0xFF90E0EF) : AppColors.accentGold,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isDuringIqamah ? 'أُذِّن الآن للصلاة (انتظار الإقامة)' : 'الصلاة القادمة',
                  style: TextStyle(
                    color: isDuringIqamah ? const Color(0xFF90E0EF) : Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Primary Visual Element: Prayer Name
          Text(
            focusedPrayerName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 34,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Countdown - Clean, Large & Prominent
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDuringIqamah
                    ? const Color(0xFF48CAE4).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isDuringIqamah ? 'متبقي للإقامة  ' : 'متبقي للأذان  ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  countdownFormatted,
                  style: TextStyle(
                    color: isDuringIqamah ? const Color(0xFF90E0EF) : AppColors.accentGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Secondary Details: Adhan and Iqamah times
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'الأذان: $focusedPrayerTimeFormatted',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (focusedPrayerIqamahFormatted != null &&
                    focusedPrayerModel!.iqamahOffsetMinutes > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '•',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
                  Text(
                    'الإقامة: $focusedPrayerIqamahFormatted (+${focusedPrayerModel.iqamahOffsetMinutes}د)',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDuringIqamah ? const Color(0xFF90E0EF) : AppColors.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
