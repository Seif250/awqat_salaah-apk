import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final p = context.palette;
    final isAllDone = totalCount > 0 && completedCount >= totalCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      category.titleArabic,
                      style: AppTypography.rowTitle(p.accentText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (category.timeDescription.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.timeDescription,
                          style: AppTypography.label(p.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                isAllDone
                    ? 'مكتمل بحمد الله'
                    : '$completedCount / $totalCount مكتملة',
                style: AppTypography.label(
                  isAllDone ? p.success : p.accentText,
                  weight: FontWeight.w600,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Text('إعادة تعيين الورد', style: AppTypography.sectionHeader(p.textPrimary)),
                      content: Text(
                        'هل تريد تصفير عدادات ${category.titleArabic} لليوم؟',
                        style: AppTypography.body(p.textPrimary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.primary,
                            foregroundColor: p.onPrimary,
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onResetCategory();
                          },
                          child: Text(
                            'تصفير',
                            style: AppTypography.meta(p.onPrimary, weight: FontWeight.w700),
                          ),
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
                    color: p.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: totalCount > 0 ? completionRate.clamp(0.0, 1.0) : 0.0,
              minHeight: 3,
              backgroundColor: p.hairline,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllDone ? p.success : p.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

