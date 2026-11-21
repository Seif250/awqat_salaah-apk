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
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 10, 8),
            decoration: BoxDecoration(
              color: p.cardElevated.withValues(alpha: 0.55),
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(4),
                bottomStart: Radius.circular(4),
                topEnd: Radius.circular(12),
                bottomEnd: Radius.circular(12),
              ),
              border: Border(
                right: BorderSide(
                  color: p.accent.withValues(alpha: 0.72),
                  width: 2.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'من فضلها',
                      style: AppTypography.badge(p.accentText, size: 11.5),
                    ),
                    if (item.reference != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: AppTypography.meta(p.textSecondary, size: 11),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.reference!,
                          style: AppTypography.meta(p.textSecondary, size: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.reward != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.reward!,
                    style: AppTypography.meta(
                      p.textPrimary.withValues(alpha: 0.86),
                      size: 12,
                      height: 1.5,
                    ),
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
    final progress = item.targetCount > 0
        ? (item.currentCount / item.targetCount).clamp(0.0, 1.0)
        : 0.0;
    final remaining =
        (item.targetCount - item.currentCount).clamp(0, item.targetCount);
    final displayNumber =
        item.currentCount == 0 ? item.targetCount : item.currentCount;

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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: p.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.currentCount} / ${item.targetCount}',
                        style: AppTypography.timeValue(
                          p.accentText,
                          size: 12,
                          weight: FontWeight.w700,
                        ),
                      ),
                      if (remaining > 0 && item.targetCount > 1)
                        Text(
                          'متبقي $remaining',
                          style: AppTypography.label(p.textSecondary, size: 10.5),
                        ),
                    ],
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: p.completedCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: p.completedCardBorder,
                        width: 0.9,
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
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: p.cardElevated,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove_rounded,
                    size: 17,
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
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (item.targetCount > 1)
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: progress),
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) =>
                                CircularProgressIndicator(
                              value: value,
                              strokeWidth: 3.0,
                              strokeCap: StrokeCap.round,
                              backgroundColor:
                                  p.primaryContainer.withValues(alpha: 0.9),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(p.primary),
                            ),
                          ),
                        ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: item.targetCount > 1 ? 37 : 42,
                        height: item.targetCount > 1 ? 37 : 42,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? p.primary
                              : p.primaryContainer.withValues(alpha: 0.72),
                          shape: BoxShape.circle,
                          border: !isCompleted && item.targetCount == 1
                              ? Border.all(
                                  color: p.primary.withValues(alpha: 0.25),
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: isCompleted &&
                                item.currentCount == item.targetCount
                            ? Icon(
                                Icons.check_rounded,
                                color: p.onPrimary,
                                size: 20,
                              )
                            : Text(
                                '$displayNumber',
                                style: AppTypography.timeValue(
                                  isCompleted ? p.onPrimary : p.accentText,
                                  size: displayNumber > 99 ? 12.5 : 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
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
