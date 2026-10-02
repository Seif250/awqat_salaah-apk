import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_system.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final times = prayerDay.allTimes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header Row: Title with Gold Accent Bar (Right) + Calendar Action (Left)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Right: Title with vertical gold accent line
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3.5,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'مواقيت اليوم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF163A29),
                    ),
                  ),
                ],
              ),

              // Left: "عرض التقويم"
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCalendarTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تقويم مواقيت الصلاة الشهري قيد التجهيز',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: isDark ? AppColors.accentGoldLight : const Color(0xFF163A29),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'عرض التقويم',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.accentGoldLight : const Color(0xFF163A29),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Unified Schedule Container (ONE Coherent White Surface with 22px border radius)
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusCard),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEFF2F0),
              width: 1.0,
            ),
            boxShadow: AppDesignSystem.cardShadow(isDark: isDark),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
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
                    thickness: 0.8,
                    color: isDark
                        ? AppColors.darkBorder.withValues(alpha: 0.6)
                        : const Color(0xFFF0F3F1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
