import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';

class DailyProgressHeader extends StatelessWidget {
  final AzkarCategory category;
  final int completedCount;
  final int totalCount;
  final double completionRate;
  final VoidCallback onResetCategory;
  final VoidCallback onOpenTasbih;

  const DailyProgressHeader({
    super.key,
    required this.category,
    required this.completedCount,
    required this.totalCount,
    required this.completionRate,
    required this.onResetCategory,
    required this.onOpenTasbih,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAllDone = totalCount > 0 && completedCount >= totalCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkCard,
                  AppColors.primaryDark.withValues(alpha: 0.5),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.accentGold.withValues(alpha: 0.12),
                ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAllDone
              ? AppColors.primaryLight.withValues(alpha: 0.4)
              : AppColors.accentGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Emoji / Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardElevated : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category.iconAssetOrEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & timing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.titleArabic,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.timeDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'إعادة تعيين الورد اليومي',
                color: isDark ? Colors.white70 : Colors.black54,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('إعادة تعيين الورد'),
                      content: Text('هل تريد تصفير عدادات ${category.titleArabic} لليوم؟'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('إلغاء'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onResetCategory();
                          },
                          child: const Text('نعم، تصفير'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Completion Progress Bar & Metric
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    minHeight: 10,
                    backgroundColor: isDark
                        ? AppColors.darkCardElevated
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isAllDone ? AppColors.primaryLight : AppColors.accentGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completedCount / $totalCount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isAllDone ? AppColors.primaryLight : AppColors.accentGold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAllDone
                    ? 'هنيئاً لك! أتممت الورد بنجاح 🌿'
                    : 'أنجزت ${(completionRate * 100).toInt()}% من الورد',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAllDone
                      ? AppColors.primaryLight
                      : (isDark ? Colors.white70 : Colors.black54),
                ),
              ),
              // Open Tasbih
              InkWell(
                onTap: onOpenTasbih,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.accentGold),
                      const SizedBox(width: 4),
                      Text(
                        'المسبحة الإلكترونية',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
