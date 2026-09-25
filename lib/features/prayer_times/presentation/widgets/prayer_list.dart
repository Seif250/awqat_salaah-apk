import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/prayer_day_model.dart';
import 'prayer_row.dart';

class PrayerList extends StatelessWidget {
  final PrayerDayModel prayerDay;
  final bool is24Hour;

  const PrayerList({
    super.key,
    required this.prayerDay,
    required this.is24Hour,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final times = prayerDay.allTimes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            'مواقيت اليوم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Unified Schedule Container (ONE Coherent Surface)
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
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
                        ? AppColors.darkBorder.withValues(alpha: 0.7)
                        : AppColors.lightBorder.withValues(alpha: 0.8),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
