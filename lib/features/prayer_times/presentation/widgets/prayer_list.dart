import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/prayer_day_model.dart';
import 'prayer_row.dart';

class PrayerList extends StatelessWidget {
  final PrayerDayModel prayerDay;
  final bool is24Hour;
  final VoidCallback? onCalendarTap;

  const PrayerList({
    super.key,
    required this.prayerDay,
    required this.is24Hour,
    this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final times = prayerDay.allTimes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Open Editorial Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'مواقيت اليوم',
                        style: AppTypography.sectionHeader(p.textPrimary).copyWith(
                          fontSize: 16.5,
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: onCalendarTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'تقويم مواقيت الصلاة الشهري قيد التجهيز',
                              style: AppTypography.meta(Colors.white, size: 13),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 17,
                          color: p.accentText,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'عرض التقويم',
                          style: AppTypography.label(p.accentText, size: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Open seamless schedule rows (no outer bordered box card)
        Column(
          children: [
            for (int i = 0; i < times.length; i++) ...[
              PrayerRow(
                prayer: times[i],
                is24Hour: is24Hour,
                isFirst: i == 0,
                isLast: i == times.length - 1,
              ),
              if (i < times.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.75,
                  color: p.hairline.withValues(alpha: p.isDark ? 0.75 : 0.85),
                ),
            ],
          ],
        ),
      ],
    );
  }
}
