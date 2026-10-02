import 'package:flutter/material.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../data/models/azkar_item_model.dart';

/// Horizontally scrollable pill-shaped tab system for Azkar categories.
class AzkarCategoryBar extends StatelessWidget {
  final AzkarCategory selectedCategory;
  final ValueChanged<AzkarCategory> onSelectCategory;
  final bool isDark;

  const AzkarCategoryBar({
    super.key,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.isDark,
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
            final icon = _categoryIcon(category);
            final label = _categoryLabel(category);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectCategory(category),
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: AppDesignSystem.pillTabDecoration(
                      isSelected: isSelected,
                      isDark: isDark,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                          ),
                        ),
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
