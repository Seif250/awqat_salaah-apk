import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';
import '../utils/azkar_ui_helpers.dart';

class DailyProgressHeader extends StatelessWidget {
  final AzkarCategory category;
  final int completedCount;
  final int totalCount;
  final double completionRate;
  final VoidCallback onResetCategory;

  const DailyProgressHeader({
    super.key,
    required this.category,
    required this.completedCount,
    required this.totalCount,
    required this.completionRate,
    required this.onResetCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAllDone = totalCount > 0 && completedCount >= totalCount;
    final percent = (completionRate * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAllDone
              ? AppColors.primaryLight.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: Category Title & Progress Badge & Reset
          Row(
            children: [
              Icon(
                category.categoryIcon,
                size: 20,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 8),

              // Category Title
              Expanded(
                child: Text(
                  category.titleArabic,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Progress badge (e.g. 3/10 • 30%)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? AppColors.primaryLight.withValues(alpha: 0.15)
                      : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAllDone
                      ? 'مكتمل بحمد الله'
                      : '$completedCount من $totalCount ($percent%)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isAllDone ? AppColors.primaryLight : AppColors.accentGold,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Reset mini button
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('إعادة تعيين الورد'),
                      content: Text('هل تريد تصفير عدادات ${category.titleArabic} لليوم؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onResetCategory();
                          },
                          child: const Text('تصفير'),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ),
            ],
          ),

          // Time Description on a clean separate line
          if (category.timeDescription.isNotEmpty) ...[
            const SizedBox(height: 3),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 28),
                child: Text(
                  category.timeDescription,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Slim progress line
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionRate,
              minHeight: 4,
              backgroundColor: isDark
                  ? AppColors.darkCardElevated
                  : AppColors.lightCardElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllDone ? AppColors.primaryLight : AppColors.accentGold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
