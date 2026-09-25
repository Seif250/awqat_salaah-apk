import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SurahBismillahHeader extends StatelessWidget {
  const SurahBismillahHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardElevated.withValues(alpha: 0.6)
            : AppColors.lightCardElevated.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: isDark ? 0.35 : 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_rounded,
            size: 14,
            color: AppColors.accentGold.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 12),
          Text(
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.accentGoldLight : AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.star_rounded,
            size: 14,
            color: AppColors.accentGold.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}
