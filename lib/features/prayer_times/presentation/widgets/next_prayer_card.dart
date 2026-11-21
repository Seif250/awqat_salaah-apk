import 'package:flutter/material.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/prayer_phase_glyph.dart';
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.035).animate(
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
    if (widget.remainingDuration.inMinutes < 5 &&
        widget.remainingDuration.inSeconds > 0) {
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDuringIqamah = widget.prayerDay.phase == PrayerPhase.duringIqamah;
    final backgroundAsset =
        _backgroundAssetForPrayer(widget.prayerDay.focusPrayerType);

    final focusedPrayerModel =
        widget.prayerDay.getPrayer(widget.prayerDay.focusPrayerType);
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

    final countdownFormatted =
        DateUtilsHelper.formatCountdown(widget.remainingDuration);
    final intervalProgress = _computeIntervalProgress(
      isDuringIqamah: isDuringIqamah,
      iqamahOffsetMinutes: focusedPrayerModel?.iqamahOffsetMinutes ?? 15,
    );

    final warmTint = const Color(0xFFFFF4D4);

    return Semantics(
      label: 'الصلاة القادمة $focusedPrayerName، متبقي $countdownFormatted',
      container: true,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppDesignSystem.heroShadow(isDark: palette.isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Contextual atmospheric scene
              Positioned.fill(
                child: Image.asset(
                  backgroundAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),

              // Clean translucent black scrim for sharp photo & high contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.42),
                        Colors.black.withValues(alpha: 0.62),
                        Colors.black.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                ),
              ),

              // Hero Editorial Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status label with clean phase glyph (no heavy pill border)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PrayerPhaseGlyph(
                          type: widget.prayerDay.focusPrayerType,
                          color: warmTint,
                          accentColor: Colors.white.withValues(alpha: 0.25),
                          size: 16,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            isDuringIqamah
                                ? 'أُذِّن الآن للصلاة'
                                : 'الصلاة القادمة',
                            style: AppTypography.label(
                              Colors.white.withValues(alpha: 0.92),
                              size: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Prayer Name + Large Tabular Countdown
                    Text(
                      focusedPrayerName,
                      style: AppTypography.heroTitle(Colors.white).copyWith(
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Text(
                        countdownFormatted,
                        style: AppTypography.heroCountdown(
                          isDuringIqamah
                              ? const Color(0xFFB3ECF7)
                              : warmTint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Open Adhan & Iqamah timing metadata line (no black box)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'الأذان $focusedPrayerTimeFormatted',
                          style: AppTypography.timeValue(
                            Colors.white.withValues(alpha: 0.95),
                            size: 13,
                            weight: FontWeight.w600,
                          ),
                        ),
                        if (focusedPrayerIqamahFormatted != null &&
                            focusedPrayerModel!.iqamahOffsetMinutes > 0) ...[
                          Text(
                            '•',
                            style: AppTypography.meta(
                              Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          Text(
                            'الإقامة $focusedPrayerIqamahFormatted',
                            style: AppTypography.timeValue(
                              warmTint,
                              size: 13,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Interval Progress Line
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: intervalProgress,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDuringIqamah ? const Color(0xFF90E0EF) : warmTint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _computeIntervalProgress({
    required bool isDuringIqamah,
    required int iqamahOffsetMinutes,
  }) {
    final remainingSeconds = widget.remainingDuration.inSeconds;
    if (remainingSeconds <= 0) return 1.0;

    if (isDuringIqamah) {
      final totalSeconds =
          (iqamahOffsetMinutes > 0 ? iqamahOffsetMinutes : 15) * 60;
      return (1.0 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0);
    }

    final target = widget.prayerDay.targetTime;
    final DateTime anchor;
    switch (widget.prayerDay.focusPrayerType) {
      case PrayerType.fajr:
        anchor = target.day == widget.prayerDay.date.day
            ? widget.prayerDay.isha.time.subtract(const Duration(days: 1))
            : widget.prayerDay.isha.time;
        break;
      case PrayerType.sunrise:
        anchor = widget.prayerDay.fajr.time;
        break;
      case PrayerType.dhuhr:
        anchor = widget.prayerDay.sunrise.time;
        break;
      case PrayerType.asr:
        anchor = widget.prayerDay.dhuhr.time;
        break;
      case PrayerType.maghrib:
        anchor = widget.prayerDay.asr.time;
        break;
      case PrayerType.isha:
      case PrayerType.none:
        anchor = widget.prayerDay.maghrib.time;
        break;
    }

    final totalSeconds = target.difference(anchor).inSeconds;
    if (totalSeconds <= 0) return 0.0;
    return (1.0 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0);
  }

  String _backgroundAssetForPrayer(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
      case PrayerType.sunrise:
        return 'assets/images/prayer_dawn.jpg';
      case PrayerType.dhuhr:
      case PrayerType.asr:
        return 'assets/images/prayer_day.jpg';
      case PrayerType.maghrib:
        return 'assets/images/prayer_sunset.jpg';
      case PrayerType.isha:
      case PrayerType.none:
        return 'assets/images/mosque_prayer_card.jpg';
    }
  }
}
