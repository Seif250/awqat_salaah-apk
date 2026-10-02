import 'dart:ui' show ImageFilter;
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
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDuringIqamah = widget.prayerDay.phase == PrayerPhase.duringIqamah;

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

    return Semantics(
      label: 'الصلاة القادمة $focusedPrayerName، متبقي $countdownFormatted',
      container: true,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.wirdBorder,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Atmospheric Grand Mosque Image
              Image.asset(
                'assets/images/mosque_prayer_card.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),

              // Subtle Blur & Cinematic Vignette Gradient for high readability on text side
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Layer: Aligned to the right in Arabic RTL
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: "الصلاة القادمة" Badge (Specification 10: dark translucent green #0F5C4D 85-90% opacity, radius 12px)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xE00F5C4D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.wirdWarmGold.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mosque_rounded,
                            color: AppColors.wirdSoftGold,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isDuringIqamah ? 'أُذِّن الآن للصلاة' : 'الصلاة القادمة',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Middle: Prayer Name & Huge Countdown (Right-aligned)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          focusedPrayerName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 27,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Text(
                            countdownFormatted,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: isDuringIqamah ? AppColors.iqamahActiveLight : AppColors.wirdSoftGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 38,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              letterSpacing: 1.0,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Pill: "الأذان 04:08 م • الإقامة 04:23 م"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'الأذان $focusedPrayerTimeFormatted',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (focusedPrayerIqamahFormatted != null &&
                              focusedPrayerModel!.iqamahOffsetMinutes > 0) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                              ),
                            ),
                            Text(
                              'الإقامة $focusedPrayerIqamahFormatted',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                color: AppColors.wirdSoftGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
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
}
