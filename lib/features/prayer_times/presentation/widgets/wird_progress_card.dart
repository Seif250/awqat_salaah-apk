import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../azkar/data/models/azkar_item_model.dart';
import '../../../azkar/presentation/bloc/azkar_state.dart';
import '../../../azkar/presentation/utils/azkar_ui_helpers.dart';

class WirdProgressCard extends StatefulWidget {
  final AzkarLoaded azkarState;
  final VoidCallback onTap;

  const WirdProgressCard({
    super.key,
    required this.azkarState,
    required this.onTap,
  });

  @override
  State<WirdProgressCard> createState() => _WirdProgressCardState();
}

class _WirdProgressCardState extends State<WirdProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    final isDone = widget.azkarState.totalCategoryCount > 0 &&
        widget.azkarState.completedCategoryCount >= widget.azkarState.totalCategoryCount;
    if (isDone) {
      _animController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant WirdProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasDone = oldWidget.azkarState.totalCategoryCount > 0 &&
        oldWidget.azkarState.completedCategoryCount >= oldWidget.azkarState.totalCategoryCount;
    final isDone = widget.azkarState.totalCategoryCount > 0 &&
        widget.azkarState.completedCategoryCount >= widget.azkarState.totalCategoryCount;

    if (!wasDone && isDone) {
      _animController.forward(from: 0.0);
    } else if (!isDone && wasDone) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAllDone = widget.azkarState.totalCategoryCount > 0 &&
        widget.azkarState.completedCategoryCount >= widget.azkarState.totalCategoryCount;
    final progress = widget.azkarState.totalCategoryCount > 0
        ? (widget.azkarState.completedCategoryCount / widget.azkarState.totalCategoryCount)
            .clamp(0.0, 1.0)
        : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppColors.darkCard,
                  isAllDone
                      ? AppColors.primaryDark.withValues(alpha: 0.7)
                      : AppColors.primaryDark.withValues(alpha: 0.4),
                ]
              : [
                  AppColors.lightCard,
                  isAllDone
                      ? AppColors.primaryContainer.withValues(alpha: 0.45)
                      : AppColors.primaryContainer.withValues(alpha: 0.25),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: isAllDone
            ? [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: isDark ? 0.18 : 0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
        border: Border.all(
          color: isAllDone
              ? AppColors.primaryLight.withValues(alpha: 0.6)
              : AppColors.accentGold.withValues(alpha: 0.3),
          width: isAllDone ? 1.4 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon or animated badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isAllDone ? AppColors.primaryLight : AppColors.accentGold)
                            .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.azkarState.selectedCategory.categoryIcon,
                        size: 22,
                        color: isAllDone ? AppColors.primaryLight : AppColors.accentGold,
                      ),
                    ),
                    if (isAllDone)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'الورد الحالي: ${widget.azkarState.selectedCategory.titleArabic}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAllDone)
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.stars_rounded,
                                      size: 14,
                                      color: AppColors.primaryLight,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'مكتمل 🎉',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAllDone
                            ? 'مبارك! أتممت هذا الورد بحمد الله • اضغط للمراجعة'
                            : 'أنجزت ${widget.azkarState.completedCategoryCount} من ${widget.azkarState.totalCategoryCount} أذكار • اضغط للمتابعة',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progress),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, _) {
                            return LinearProgressIndicator(
                              value: val,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isAllDone ? AppColors.primaryLight : AppColors.accentGold,
                              ),
                              minHeight: 4,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
