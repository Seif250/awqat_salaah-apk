import 'package:flutter/material.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/prayer_phase_glyph.dart';
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final isInIqamahWindow = prayer.isCurrentlyInIqamahWindow(now);
    final isSunrise = prayer.type == PrayerType.sunrise;

    final formattedTime = DateUtilsHelper.formatPrayerTime(
      prayer.time,
      is24Hour: is24Hour,
    );

    final iqamahTimeFormatted =
        prayer.iqamahTime != null && prayer.iqamahOffsetMinutes > 0
            ? DateUtilsHelper.formatPrayerTime(
                prayer.iqamahTime!,
                is24Hour: is24Hour,
              )
            : null;

    final isHighlighted = prayer.isNext || prayer.isCurrent || isInIqamahWindow;
    final isPassed = !isHighlighted && prayer.time.isBefore(now);

    final semanticDescription = StringBuffer(prayer.type.nameArabic)
      ..write('، وقت الأذان $formattedTime');
    if (iqamahTimeFormatted != null) {
      semanticDescription.write('، موعد الإقامة $iqamahTimeFormatted');
    }
    if (isInIqamahWindow) {
      semanticDescription.write('، أُذِّن الآن');
    } else if (prayer.isNext) {
      semanticDescription.write('، الصلاة القادمة');
    }

    // Calm complementary highlight so NextPrayerCard remains primary focal point
    final Color glyphColor = isInIqamahWindow
        ? p.iqamah
        : (isHighlighted
            ? p.accentText
            : (isSunrise ? p.sunrise : p.textSecondary));

    return Semantics(
      label: semanticDescription.toString(),
      container: true,
      excludeSemantics: true,
      child: Container(
        margin: isHighlighted
            ? const EdgeInsets.symmetric(vertical: 3)
            : EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: isHighlighted
            ? BoxDecoration(
                color: isInIqamahWindow ? p.iqamahContainer : p.cardElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  right: BorderSide(
                    color: isInIqamahWindow ? p.iqamah : p.accent,
                    width: 3,
                  ),
                ),
              )
            : null,
        child: Row(
          children: [
            // Clean astronomical phase glyph directly without repetitive grey circles
            SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: PrayerPhaseGlyph(
                  type: prayer.type,
                  color: glyphColor,
                  accentColor: isHighlighted
                      ? p.accent.withValues(alpha: 0.25)
                      : glyphColor.withValues(alpha: 0.14),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Prayer Name & Calm Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        prayer.type.nameArabic,
                        style: AppTypography.rowTitle(
                          isPassed ? p.textSecondary : p.textPrimary,
                          weight:
                              isHighlighted ? FontWeight.w700 : FontWeight.w600,
                        ).copyWith(fontSize: 15.5),
                      ),
                      if (isInIqamahWindow)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: p.iqamah.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'أُذِّن الآن',
                            style: AppTypography.badge(p.iqamah, size: 10.5),
                          ),
                        )
                      else if (prayer.isNext)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: p.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'القادمة',
                                style: AppTypography.badge(
                                  p.accentText,
                                  size: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (isSunrise)
                    Text(
                      'شروق الشمس',
                      style: AppTypography.meta(p.textSecondary, size: 11.5),
                    )
                  else
                    Text(
                      iqamahTimeFormatted != null &&
                              prayer.iqamahOffsetMinutes > 0
                          ? 'الأذان $formattedTime  •  الإقامة $iqamahTimeFormatted'
                          : 'الأذان $formattedTime',
                      style: AppTypography.meta(
                        isPassed
                            ? p.textSecondary.withValues(alpha: 0.85)
                            : p.textSecondary,
                        size: 11.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Tabular Time Column
            Text(
              formattedTime,
              style: AppTypography.timeValue(
                isHighlighted
                    ? p.accentText
                    : (isPassed ? p.textSecondary : p.textPrimary),
                size: 16,
                weight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
