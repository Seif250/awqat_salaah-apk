import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/azkar_item_model.dart';

/// Horizontally scrollable pill-shaped tab system for Azkar categories.
class AzkarCategoryBar extends StatelessWidget {
  final AzkarCategory selectedCategory;
  final ValueChanged<AzkarCategory> onSelectCategory;
  final bool isDark;
  final Set<AzkarCategory> completedCategories;

  const AzkarCategoryBar({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.isDark,
    this.completedCategories = const {},
  });

  IconData _categoryIcon(AzkarCategory cat) {
    switch (cat) {
      case AzkarCategory.morning:
        return Icons.wb_sunny_rounded;
      case AzkarCategory.evening:
        return Icons.wb_twilight_outlined;
      case AzkarCategory.postPrayer:
        return Icons.mosque_outlined;
      case AzkarCategory.sleep:
        return Icons.bedtime_outlined;
      case AzkarCategory.qiyam:
        return Icons.mode_night_outlined;
      case AzkarCategory.supplications:
        return Icons.auto_awesome_outlined;
      case AzkarCategory.general:
        return Icons.all_inclusive_rounded;
      case AzkarCategory.custom:
        return Icons.bookmark_outline_rounded;
    }
  }

  String _categoryLabel(AzkarCategory cat) {
    switch (cat) {
      case AzkarCategory.morning:
        return 'أذكار الصباح';
      case AzkarCategory.evening:
        return 'أذكار المساء';
      case AzkarCategory.postPrayer:
        return 'بعد الصلاة';
      case AzkarCategory.sleep:
        return 'أذكار النوم';
      case AzkarCategory.qiyam:
        return 'قيام الليل';
      case AzkarCategory.supplications:
        return 'مفاتيح الإجابة';
      case AzkarCategory.general:
        return 'أذكار عامة';
      case AzkarCategory.custom:
        return 'أذكاري';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.transparent,
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          children: AzkarCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            final isCategoryDone = completedCategories.contains(category);
            final icon = _categoryIcon(category);
            final label = _categoryLabel(category);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectCategory(category),
                  borderRadius:
                      BorderRadius.circular(AppDesignSystem.radiusPill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? p.primary : p.cardElevated,
                      borderRadius:
                          BorderRadius.circular(AppDesignSystem.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected ? p.onPrimary : p.textSecondary,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: AppTypography.label(
                            isSelected ? p.onPrimary : p.textPrimary,
                            size: 13,
                          ).copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (isCategoryDone) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 13,
                            color: isSelected ? p.accentLight : p.accentText,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
