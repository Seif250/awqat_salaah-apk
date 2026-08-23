import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart';

class HeaderWidget extends StatelessWidget {
  final String cityName;
  final String countryName;
  final VoidCallback onLocationTap;

  const HeaderWidget({
    super.key,
    required this.cityName,
    required this.countryName,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final gregorianDate = DateUtilsHelper.getGregorianDateFormatted(now, locale: 'ar');
    final hijriDate = DateUtilsHelper.getHijriDateFormatted(now, locale: 'ar');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // City Selector Button
          InkWell(
            onTap: onLocationTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkCard : Colors.white).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$cityName، $countryName',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Hijri Date
          Text(
            hijriDate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.accentGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),

          // Gregorian Date
          Text(
            gregorianDate,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
