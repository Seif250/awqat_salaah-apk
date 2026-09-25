import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/azkar_item_model.dart';

/// Lightweight list row for custom Adhkar where Arabic text is the hero.
class CustomDhikrTile extends StatelessWidget {
  final AzkarItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onIncrement;
  final VoidCallback? onReset;

  const CustomDhikrTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.onIncrement,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasSource = item.reference != null && item.reference!.trim().isNotEmpty;
    final hasReward = item.reward != null && item.reward!.trim().isNotEmpty;
    final isCompleted = item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppColors.primary.withValues(alpha: 0.35)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onIncrement,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Title, repetition badge, and overflow action menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dhikr Title
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.accentGoldLight : AppColors.primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Repetition badge / counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle_rounded : Icons.repeat_rounded,
                            size: 13,
                            color: isCompleted ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.targetCount > 0
                                ? '${toArabicDigits(item.currentCount)} / ${toArabicDigits(item.targetCount)}'
                                : '${toArabicDigits(item.targetCount)} مرة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? AppColors.primary : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Overflow Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        } else if (value == 'reset' && onReset != null) {
                          onReset!();
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('تعديل الذكر', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                            ],
                          ),
                        ),
                        if (item.currentCount > 0 && onReset != null)
                          const PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(Icons.refresh_rounded, size: 18, color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text('تصفير العداد', style: TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('حذف الذكر',
                                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Hero Arabic Text
                Text(
                  item.arabicText,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16.5,
                    height: 1.65,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.right,
                ),

                // Optional Footer: Category / Source
                if (hasSource || hasReward) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (hasSource)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 12, color: AppColors.accentGold),
                            const SizedBox(width: 4),
                            Text(
                              item.reference!,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ],
                        ),
                      if (hasReward)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_outline_rounded, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              item.reward!,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
