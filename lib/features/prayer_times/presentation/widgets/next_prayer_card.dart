import 'package:flutter/material.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/prayer_day_model.dart';

class NextPrayerCard extends StatefulWidget {
  final PrayerDayModel prayerDay;
  final Duration remainingDuration;
  final bool is24Hour;

  const NextPrayerCard({
    super.key,
    required this.prayerDay,
    required this.remainingDuration,
    required this.is24Hour,
  });

  @override
  State<NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends State<NextPrayerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(NextPrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePulse();
  }

  void _updatePulse() {
    // Pulse when less than 5 minutes remaining
    if (widget.remainingDuration.inMinutes < 5 && widget.remainingDuration.inSeconds > 0) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
    final isDuringIqamah = widget.prayerDay.phase == PrayerPhase.duringIqamah;
    final isUrgent = widget.remainingDuration.inMinutes < 5 && widget.remainingDuration.inSeconds > 0;

    final focusedPrayerModel = widget.prayerDay.getPrayer(widget.prayerDay.focusPrayerType);
    final focusedPrayerName = widget.prayerDay.focusPrayerType.nameArabic;

    final focusedPrayerTimeFormatted = focusedPrayerModel != null
        ? DateUtilsHelper.formatPrayerTime(
            focusedPrayerModel.time,
            is24Hour: widget.is24Hour,
          )
        : '--:--';

    final focusedPrayerIqamahFormatted = focusedPrayerModel?.iqamahTime != null
        ? DateUtilsHelper.formatPrayerTime(
            focusedPrayerModel!.iqamahTime!,
            is24Hour: widget.is24Hour,
          )
        : null;

    final countdownFormatted = DateUtilsHelper.formatCountdown(widget.remainingDuration);

    final nextPrayerAnnouncement = isDuringIqamah
        ? 'أُذّن الآن لصلاة $focusedPrayerName، متبقي للإقامة $countdownFormatted${focusedPrayerIqamahFormatted != null ? "، وقت الإقامة $focusedPrayerIqamahFormatted" : ""}'
        : 'الصلاة القادمة $focusedPrayerName، متبقي للأذان $countdownFormatted، موعد الأذان $focusedPrayerTimeFormatted${focusedPrayerIqamahFormatted != null ? "، وموعد الإقامة $focusedPrayerIqamahFormatted" : ""}';

    return Semantics(
      label: nextPrayerAnnouncement,
      container: true,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDuringIqamah
                ? AppColors.iqamahCardGradient
                : (isDark
                    ? AppColors.nextPrayerDarkGradient
                    : AppColors.nextPrayerLightGradient),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            // Subtle glow when urgent
            if (isUrgent)
              BoxShadow(
                color: (isDuringIqamah ? AppColors.iqamahActive : AppColors.accentGold)
                    .withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 1,
              ),
          ],
          border: Border.all(
            color: isDuringIqamah
                ? AppColors.iqamahActive.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Top Label: Small Label 'الصلاة القادمة'
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDuringIqamah
                    ? AppColors.iqamahActive.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPrayerIcon(widget.prayerDay.focusPrayerType),
                    color: isDuringIqamah ? AppColors.iqamahActiveLight : AppColors.accentGold,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isDuringIqamah ? 'أُذِّن الآن للصلاة' : 'الصلاة القادمة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: isDuringIqamah ? AppColors.iqamahActiveLight : Colors.white.withValues(alpha: 0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Prayer Name: Large 'العصر'
            Text(
              focusedPrayerName,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),

            // Countdown: Very Large '01:17:22' - largest visual element inside card
            ScaleTransition(
              scale: _pulseAnimation,
              child: Text(
                countdownFormatted,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isDuringIqamah ? AppColors.iqamahActiveLight : AppColors.accentGoldLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Compact info: 'الأذان 04:12 PM'  'الإقامة 04:27 PM'
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الأذان $focusedPrayerTimeFormatted',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
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
                      'الإقامة $focusedPrayerIqamahFormatted',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: isDuringIqamah ? AppColors.iqamahActiveLight : AppColors.accentGoldLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
