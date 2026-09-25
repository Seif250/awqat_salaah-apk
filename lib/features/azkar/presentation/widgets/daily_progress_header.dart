import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAllDone = totalCount > 0 && completedCount >= totalCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAllDone
              ? AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Category Info & Progress & Reset
          Row(
            children: [
              // Category Title
              Expanded(
                child: Row(
                  children: [
                    Text(
                      category.titleArabic,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.timeDescription.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.timeDescription,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Progress Text (e.g. 3 / 13 مكتملة)
              Text(
                isAllDone
                    ? 'مكتمل بحمد الله'
                    : '$completedCount / $totalCount مكتملة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isAllDone
                      ? AppColors.primary
                      : (isDark ? AppColors.accentGoldLight : AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 4),

              // Reset subtle button
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
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // Slim progress line (Subtle, 3px)
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? completionRate.clamp(0.0, 1.0) : 0.0,
              minHeight: 3,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllDone ? AppColors.primary : AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

