import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';

class AzkarCard extends StatelessWidget {
  final AzkarItem item;
  final VoidCallback onIncrement;
  final VoidCallback onToggleComplete;
  final VoidCallback? onEdit;

  const AzkarCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onToggleComplete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = item.isCompleted;

    final double progress = item.targetCount > 0
        ? (item.currentCount / item.targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? AppColors.primaryLight.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isCompleted ? 1.4 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? AppColors.primaryLight.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onIncrement();
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & Done Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (isCompleted)
                              Container(
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

                      // Target badge
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
                          constraints: const BoxConstraints(),
                          onPressed: onEdit,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Arabic Text
                  Text(
                    item.arabicText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16.5,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFECEFF1) : const Color(0xFF263238),
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
                                const Text('📖 ', style: TextStyle(fontSize: 11)),
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

                  const SizedBox(height: 14),

                  // Progress Bar & Counter Action
                  Row(
                    children: [
                      // Linear progress bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: isDark
                                    ? AppColors.darkCardElevated
                                    : AppColors.lightCardElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted ? AppColors.primaryLight : AppColors.accentGold,
                                ),
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

                      // Increment Tap Counter Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onIncrement();
                        },
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
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onToggleComplete();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
