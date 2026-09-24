import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';

/// Top row of AzkarCard containing drag handle, title, checkmark, target count, and action buttons.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (isReorderMode && reorderIndex != null) ...[
          ReorderableDragStartListener(
            index: reorderIndex!,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsetsDirectional.only(end: 8),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: isDark ? 0.24 : 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.drag_indicator_rounded,
                    color: AppColors.accentGold,
                    size: 22,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'اسحب',
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
        Expanded(
          child: Row(
            children: [
              if (isCompleted && !isReorderMode)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isCompleted
                        ? AppColors.primaryLight
                        : (isDark ? Colors.white : AppColors.primaryDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        if (isReorderMode) ...[
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded, size: 22),
            color: onMoveUp != null
                ? AppColors.accentGold
                : (isDark ? Colors.white24 : Colors.black26),
            tooltip: 'تحريك لأعلى',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onMoveUp,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward_rounded, size: 22),
            color: onMoveDown != null
                ? AppColors.accentGold
                : (isDark ? Colors.white24 : Colors.black26),
            tooltip: 'تحريك لأسفل',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onMoveDown,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primaryLight.withValues(alpha: 0.12)
                  : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCompleted
                    ? AppColors.primaryLight.withValues(alpha: 0.3)
                    : AppColors.accentGold.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              '${item.targetCount} ${item.targetCount == 1 ? "مرة" : "مرات"}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isCompleted ? AppColors.primaryLight : AppColors.accentGold,
              ),
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.edit_note_rounded,
                size: 22,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              tooltip: 'تعديل أو حذف الذكر',
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: onEdit,
            ),
          ],
        ],
      ],
    );
  }
}

/// Middle section of AzkarCard containing the Arabic text, and optional reward/reference box.
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
        // Arabic Text
        Text(
          item.arabicText,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16.5,
            height: 1.8,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.azkarTextDark : AppColors.azkarTextLight,
          ),
          textAlign: TextAlign.start,
          textDirection: TextDirection.rtl,
        ),

        // Reference & Reward (if present)
        if (item.reward != null || item.reference != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.5)
                  : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentGold.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.reward != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('✨ ', style: TextStyle(fontSize: 13)),
                      Expanded(
                        child: Text(
                          item.reward!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                if (item.reference != null) ...[
                  if (item.reward != null) const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 13, color: AppColors.accentGold),
                      const SizedBox(width: 4),
                      Text(
                        item.reference!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.accentGold.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
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

/// Bottom footer of AzkarCard with animated progress bar, count pill, and check toggle.
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
    return Row(
      children: [
        // Animated linear progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.darkCardElevated
                          : AppColors.lightCardElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? AppColors.primaryLight : AppColors.accentGold,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isCompleted
                    ? 'اكتمل الذكر بحمد الله'
                    : 'تم: ${item.currentCount} من أصل ${item.targetCount}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isCompleted
                      ? AppColors.primaryLight
                      : (isDark ? Colors.white60 : Colors.black54),
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Animated Increment Tap Counter Button
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? const LinearGradient(
                        colors: [
                          AppColors.primaryLight,
                          AppColors.primary,
                        ],
                      )
                    : const LinearGradient(
                        colors: [
                          AppColors.accentGold,
                          AppColors.accentAmber,
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (isCompleted ? AppColors.primary : AppColors.accentGold)
                        .withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
                    size: 16,
                    color: isCompleted ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.currentCount}/${item.targetCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isCompleted ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 4),

        // Direct Complete Toggle Icon
        IconButton(
          icon: Icon(
            isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            color: isCompleted ? AppColors.primaryLight : Colors.grey,
            size: 22,
          ),
          tooltip: isCompleted ? 'إلغاء التحديد' : 'تحديد كمقروء',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: isReorderMode
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onToggleComplete();
                },
        ),
      ],
    );
  }
}
