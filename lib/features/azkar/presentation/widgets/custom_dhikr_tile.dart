import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final p = context.palette;

    final hasSource =
        item.reference != null && item.reference!.trim().isNotEmpty;
    final hasReward = item.reward != null && item.reward!.trim().isNotEmpty;
    final isCompleted = item.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:
            isCompleted ? p.primaryContainer.withValues(alpha: 0.45) : p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? p.primary.withValues(alpha: 0.35) : p.hairline,
          width: 0.75,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onIncrement != null
              ? () {
                  HapticFeedback.selectionClick();
                  onIncrement!();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top row: Title, repetition badge, and overflow action menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: AppTypography.rowTitle(p.accentText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            isCompleted ? p.primaryContainer : p.cardElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.repeat_rounded,
                            size: 13,
                            color: isCompleted ? p.success : p.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.targetCount > 0
                                ? '${toArabicDigits(item.currentCount)} / ${toArabicDigits(item.targetCount)}'
                                : '${toArabicDigits(item.targetCount)} مرة',
                            style: AppTypography.label(
                              isCompleted ? p.success : p.textSecondary,
                              weight: FontWeight.w700,
                            ).copyWith(fontFeatures: const [
                              FontFeature.tabularFigures()
                            ]),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded,
                          size: 20, color: p.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
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
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined, size: 18),
                              const SizedBox(width: 8),
                              Text('تعديل الذكر',
                                  style: AppTypography.body(p.textPrimary)),
                            ],
                          ),
                        ),
                        if (item.currentCount > 0 && onReset != null)
                          PopupMenuItem(
                            value: 'reset',
                            child: Row(
                              children: [
                                Icon(Icons.refresh_rounded,
                                    size: 18, color: p.textSecondary),
                                const SizedBox(width: 8),
                                Text('تصفير العداد',
                                    style: AppTypography.body(p.textPrimary)),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 18, color: p.error),
                              const SizedBox(width: 8),
                              Text('حذف الذكر',
                                  style: AppTypography.body(p.error)),
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
                  style: AppTypography.dhikrBody(p.textPrimary, scale: 0.94),
                  textAlign: TextAlign.right,
                ),

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
                            Icon(Icons.menu_book_rounded,
                                size: 12, color: p.accent),
                            const SizedBox(width: 4),
                            Text(
                              item.reference!,
                              style: AppTypography.badge(p.accentText),
                            ),
                          ],
                        ),
                      if (hasReward)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_outline_rounded,
                                size: 12, color: p.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              item.reward!,
                              style: AppTypography.badge(p.textSecondary),
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
