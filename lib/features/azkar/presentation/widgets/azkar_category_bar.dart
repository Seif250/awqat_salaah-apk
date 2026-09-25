import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';
import '../utils/azkar_ui_helpers.dart';

/// Horizontally scrollable segmented tab system for Azkar categories.
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
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
      ),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: AzkarCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelectCategory(category),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.25)
                              : const Color(0xFFE8F5E9))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: isDark ? 0.5 : 0.3)
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.categoryIcon,
                          size: 15,
                          color: isSelected
                              ? (isDark ? AppColors.accentGoldLight : AppColors.primaryDark)
                              : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category.titleArabic,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? AppColors.accentGoldLight : AppColors.primaryDark)
                                : (isDark ? Colors.white60 : const Color(0xFF4B5563)),
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

