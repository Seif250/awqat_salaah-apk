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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? AppColors.primaryLight.withValues(alpha: 0.6)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isCompleted ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? AppColors.primaryLight.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onIncrement();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                item.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primaryLight.withValues(alpha: 0.15)
                              : (isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.primaryLight.withValues(alpha: 0.3)
                                : AppColors.accentGold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${item.targetCount} ${item.targetCount == 1 ? "مرة" : "مرات"}',
                          style: TextStyle(
                            fontSize: 12,
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
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                          tooltip: 'تعديل أو حذف الذكر',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: onEdit,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Arabic Text
                  Text(
                    item.arabicText,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17.5,
                      height: 1.85,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFECEFF1) : const Color(0xFF263238),
                    ),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                  ),

                  // Reference & Reward (if present)
                  if (item.reward != null || item.reference != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground.withValues(alpha: 0.6)
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.reward != null)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('✨ ', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Text(
                                    item.reward!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.45,
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
                            if (item.reward != null) const SizedBox(height: 6),
                            Row(
                              children: [
                                const Text('📖 ', style: TextStyle(fontSize: 12)),
                                Text(
                                  item.reference!,
                                  style: TextStyle(
                                    fontSize: 12,
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

                  const SizedBox(height: 16),

                  // Progress Bar & Counter Action
                  Row(
                    children: [
                      // Linear progress bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: isDark
                                    ? AppColors.darkCardElevated
                                    : AppColors.lightCardElevated,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted ? AppColors.primaryLight : AppColors.accentGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isCompleted
                                  ? 'اكتمل الذكر بحمد الله'
                                  : 'تم: ${item.currentCount} من أصل ${item.targetCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isCompleted
                                    ? AppColors.primaryLight
                                    : (isDark ? Colors.white60 : Colors.black54),
                                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Increment Tap Counter Button
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          onIncrement();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isCompleted
                                ? LinearGradient(
                                    colors: [
                                      AppColors.primaryLight,
                                      AppColors.primary,
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.accentGold,
                                      AppColors.accentAmber,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: (isCompleted ? AppColors.primary : AppColors.accentGold)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle_rounded : Icons.fingerprint_rounded,
                                size: 18,
                                color: isCompleted ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${item.currentCount}/${item.targetCount}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isCompleted ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Direct Complete Toggle Icon
                      IconButton(
                        icon: Icon(
                          isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          color: isCompleted ? AppColors.primaryLight : Colors.grey,
                        ),
                        tooltip: isCompleted ? 'إلغاء التحديد' : 'تحديد كمقروء',
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
