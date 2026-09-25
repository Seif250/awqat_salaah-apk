import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';

/// Top row of AzkarCard containing title, completion check, target repetition badge, and optional actions.
class AzkarCardHeader extends StatelessWidget {
  final AzkarItem item;
  final bool isCompleted;
  final bool isDark;
  final bool isReorderMode;
  final int? reorderIndex;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onEdit;

  const AzkarCardHeader({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.isDark,
    required this.isReorderMode,
    this.reorderIndex,
    this.onMoveUp,
    this.onMoveDown,
    this.onEdit,
  });

  String _formatTargetCount(int count) {
    if (count == 1) return 'مرة واحدة';
    if (count == 2) return 'مرتان';
    if (count >= 3 && count <= 10) return '$count مرات';
    return '$count مرة';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isReorderMode && reorderIndex != null) ...[
          ReorderableDragStartListener(
            index: reorderIndex!,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsetsDirectional.only(end: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                  width: 0.8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.drag_indicator_rounded,
                    color: AppColors.accentGold,
                    size: 18,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'اسحب',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Title and Completion Status
        Expanded(
          child: Row(
            children: [
              if (isCompleted && !isReorderMode) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: isCompleted
                        ? AppColors.primary
                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Reorder Actions or Repetition Badge & Edit
        if (isReorderMode) ...[
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded, size: 20),
            color: onMoveUp != null
                ? AppColors.accentGold
                : (isDark ? Colors.white24 : Colors.black26),
            tooltip: 'تحريك لأعلى',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onMoveUp,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward_rounded, size: 20),
            color: onMoveDown != null
                ? AppColors.accentGold
                : (isDark ? Colors.white24 : Colors.black26),
            tooltip: 'تحريك لأسفل',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onMoveDown,
          ),
        ] else ...[
          // Subtle Repetition Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: isCompleted
                  ? (isDark ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFE8F5E9))
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                width: 0.7,
              ),
            ),
            child: Text(
              _formatTargetCount(item.targetCount),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? AppColors.primary
                    : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
              ),
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.edit_note_rounded,
                size: 20,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              tooltip: 'تعديل أو حذف الذكر',
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: onEdit,
            ),
          ],
        ],
      ],
    );
  }
}

/// Middle section of AzkarCard containing the Arabic Dhikr text (THE HERO), and optional reward/reference.
class AzkarCardBody extends StatelessWidget {
  final AzkarItem item;
  final bool isDark;

  const AzkarCardBody({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Arabic Dhikr Text (THE HERO - large readable font, comfortable line height)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            item.arabicText,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 19.5,
              height: 1.9,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.azkarTextDark : AppColors.azkarTextLight,
            ),
            textAlign: TextAlign.start,
            textDirection: TextDirection.rtl,
          ),
        ),

        // Reference & Reward (Subtle, visually separated)
        if (item.reward != null || item.reference != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                width: 0.6,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.reward != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨ ', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Text(
                          item.reward!,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            height: 1.5,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.reference != null) ...[
                  if (item.reward != null) const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 13,
                        color: AppColors.accentGold.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.reference!,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            height: 1.4,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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

/// Bottom footer of AzkarCard with animated thin progress bar, clear counter pill, and secondary check toggle.
class AzkarCardProgressFooter extends StatelessWidget {
  final AzkarItem item;
  final bool isCompleted;
  final bool isDark;
  final bool isReorderMode;
  final double progress;
  final Animation<double> scaleAnimation;
  final VoidCallback onIncrement;
  final VoidCallback onToggleComplete;

  const AzkarCardProgressFooter({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.isDark,
    required this.isReorderMode,
    required this.progress,
    required this.scaleAnimation,
    required this.onIncrement,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Counter Row: Counter Pill (Right/Start), Subtitle (Center), Checkbox (Left/End)
        Row(
          children: [
            // Interactive Counter Pill (Calm, non-loud, scale animation)
            GestureDetector(
              onTap: isReorderMode
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      onIncrement();
                    },
              child: ScaleTransition(
                scale: scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : const Color(0xFFE8F5E9))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : (isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_rounded : Icons.fingerprint_rounded,
                        size: 14,
                        color: isCompleted
                            ? AppColors.primary
                            : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item.currentCount}/${item.targetCount}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: isCompleted
                              ? AppColors.primary
                              : (isDark ? Colors.white : AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Secondary Status Subtitle
            Expanded(
              child: Text(
                isCompleted
                    ? 'اكتمل بحمد الله'
                    : '${item.currentCount} من أصل ${item.targetCount}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.5,
                  color: isCompleted
                      ? AppColors.primary
                      : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                ),
              ),
            ),

            // Secondary Checkbox Toggle
            IconButton(
              icon: Icon(
                isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: isCompleted
                    ? AppColors.primary
                    : (isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
                size: 20,
              ),
              tooltip: isCompleted ? 'إلغاء التحديد' : 'تحديد كمقروء',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: isReorderMode
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onToggleComplete();
                    },
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Slim, Subtle Linear Progress Line (3px)
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 3.0,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF3F4F6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.primary : AppColors.primaryLight,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
