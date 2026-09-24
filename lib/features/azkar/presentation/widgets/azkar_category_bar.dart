import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';
import '../utils/azkar_ui_helpers.dart';

/// Horizontal scrolling bar with Islamic category filter chips.
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: AzkarCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: FilterChip(
                showCheckmark: false,
                avatar: Icon(
                  category.categoryIcon,
                  size: 16,
                  color: isSelected ? AppColors.primaryLight : Colors.grey,
                ),
                label: Text(category.titleArabic),
                selected: isSelected,
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.16),
                backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryLight.withValues(alpha: 0.6)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: isSelected ? 1.2 : 0.8,
                ),
                labelStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryLight
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                onSelected: (_) => onSelectCategory(category),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
