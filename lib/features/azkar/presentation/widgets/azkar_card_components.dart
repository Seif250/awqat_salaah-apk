import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/azkar_item_model.dart';

/// Top header row of AzkarCard containing index number badge, title, and action icons.
class AzkarCardHeader extends StatelessWidget {
  final AzkarItem item;
  final int itemIndex;
  final bool isCompleted;
  final bool isDark;
  final bool isReorderMode;
  final int? reorderIndex;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final bool isBookmarked;

  const AzkarCardHeader({
    super.key,
    required this.item,
    required this.itemIndex,
    required this.isCompleted,
    required this.isDark,
    required this.isReorderMode,
    this.reorderIndex,
    this.onMoveUp,
    this.onMoveDown,
    this.onEdit,
    this.onDelete,
    this.onBookmark,
    this.onShare,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Right side (in RTL): Index Pill + Title
        Expanded(
          child: Row(
            children: [
              if (isReorderMode && reorderIndex != null) ...[
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    decoration: BoxDecoration(
                      color: p.cardElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drag_indicator_rounded,
                          color: p.accentText,
                          size: 18,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'اسحب',
                          style: AppTypography.badge(p.accentText, size: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: p.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$itemIndex',
                    style: AppTypography.timeValue(
                      p.accentText,
                      size: 12.5,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.rowTitle(
                    isCompleted ? p.accentText : p.textPrimary,
                    weight: FontWeight.w700,
                  ).copyWith(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),

        if (isReorderMode) ...[
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded, size: 20),
            color: onMoveUp != null
                ? p.accentText
                : p.textSecondary.withValues(alpha: 0.3),
            tooltip: 'تحريك لأعلى',
            visualDensity: VisualDensity.compact,
            onPressed: onMoveUp,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward_rounded, size: 20),
            color: onMoveDown != null
                ? p.accentText
                : p.textSecondary.withValues(alpha: 0.3),
            tooltip: 'تحريك لأسفل',
            visualDensity: VisualDensity.compact,
            onPressed: onMoveDown,
          ),
        ] else ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 19),
                color: p.textSecondary,
                tooltip: 'مشاركة الذكر',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                onPressed: onShare,
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.mode_edit_outline_rounded, size: 19),
                  color: p.accentText,
                  tooltip: 'تعديل الذكر',
                  padding: const EdgeInsets.all(6),
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: onEdit,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Calm open body for Arabic Dhikr text directly on the card canvas (no nested box-inside-box)
/// followed by a hairline-accented virtue/source block.
class AzkarCardBody extends StatelessWidget {
  final AzkarItem item;
  final bool isDark;
  final double fontScale;

  const AzkarCardBody({
    super.key,
    required this.item,
    required this.isDark,
    this.fontScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isQuranic = item.title.contains('آية') ||
        item.title.contains('المعوذات') ||
        item.title.contains('سورة') ||
        item.title.contains('خواتيم') ||
        item.title.contains('الكافرون') ||
        item.title.contains('الإخلاص') ||
        item.title.contains('الفلق') ||
        item.title.contains('الناس');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            item.arabicText,
            style: AppTypography.dhikrBody(
              p.textPrimary,
              scale: fontScale,
              isQuranic: isQuranic,
            ),
            textAlign: TextAlign.start,
            textDirection: TextDirection.rtl,
          ),
        ),
        if (item.reward != null || item.reference != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 4, 6),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: p.accent.withValues(alpha: 0.7),
                  width: 2.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'من فضلها',
                  style: AppTypography.badge(p.accentText, size: 12),
                ),
                if (item.reward != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.reward!,
                    style: AppTypography.meta(
                      p.textPrimary.withValues(alpha: 0.85),
                      size: 12,
                      height: 1.48,
                    ),
                  ),
                ],
                if (item.reference != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.reference!,
                    style: AppTypography.meta(p.textSecondary, size: 11.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom footer of AzkarCard with completion pill and interactive counter.
class AzkarCardFooter extends StatelessWidget {
  final AzkarItem item;
  final bool isCompleted;
  final bool isDark;
  final bool isReorderMode;
  final Animation<double> scaleAnimation;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onToggleComplete;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  const AzkarCardFooter({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.isDark,
    required this.isReorderMode,
    required this.scaleAnimation,
    required this.onIncrement,
    required this.onDecrement,
    required this.onToggleComplete,
    this.onBookmark,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompleted) ...[
                InkWell(
                  onTap: isReorderMode
                      ? null
                      : () {
                          HapticFeedback.heavyImpact();
                          onToggleComplete();
                        },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: p.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: p.accentText,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'إتمام الورد',
                          style: AppTypography.badge(p.accentText, size: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
                if (item.currentCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${item.currentCount} / ${item.targetCount}',
                    style: AppTypography.timeValue(
                      p.accentText,
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ] else ...[
                InkWell(
                  onTap: isReorderMode
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onToggleComplete();
                        },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: p.completedCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: p.completedCardBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: p.accentText,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.currentCount > item.targetCount
                              ? 'مكتمل (${item.currentCount})'
                              : 'مكتمل بحمد الله',
                          style: AppTypography.badge(p.accentText, size: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.currentCount > 0 && !isReorderMode) ...[
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDecrement();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: p.cardElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: p.textSecondary,
                  ),
                ),
              ),
            ],
            ScaleTransition(
              scale: scaleAnimation,
              child: InkWell(
                onTap: isReorderMode
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        onIncrement();
                      },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted ? p.primary : p.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: !isCompleted && item.currentCount > 0
                        ? Border.all(color: p.primary.withValues(alpha: 0.45))
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted && item.currentCount == item.targetCount
                      ? Icon(
                          Icons.check_rounded,
                          color: p.onPrimary,
                          size: 22,
                        )
                      : Text(
                          item.currentCount == 0
                              ? '${item.targetCount}'
                              : '${item.currentCount}',
                          style: AppTypography.timeValue(
                            isCompleted ? p.onPrimary : p.accentText,
                            size: (item.currentCount == 0
                                        ? item.targetCount
                                        : item.currentCount) >
                                    99
                                ? 13.5
                                : 16.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
