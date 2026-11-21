import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final p = context.palette;
    final isAllDone = widget.azkarState.totalCategoryCount > 0 &&
        widget.azkarState.completedCategoryCount >= widget.azkarState.totalCategoryCount;
    final progress = widget.azkarState.totalCategoryCount > 0
        ? (widget.azkarState.completedCategoryCount / widget.azkarState.totalCategoryCount)
            .clamp(0.0, 1.0)
        : 0.0;

    final statusColor = isAllDone ? p.success : p.accentText;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      decoration: BoxDecoration(
        color: isAllDone ? p.primaryContainer : p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAllDone ? p.primary.withValues(alpha: 0.35) : p.hairline,
          width: isAllDone ? 1.2 : 0.75,
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
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: p.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.azkarState.selectedCategory.categoryIcon,
                        size: 22,
                        color: isAllDone ? p.success : p.accent,
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
                              color: p.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: p.card, width: 1.5),
                            ),
                            child: Icon(Icons.check, size: 10, color: p.onPrimary),
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
                              style: AppTypography.rowTitle(p.textPrimary),
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
                                  color: p.card,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.stars_rounded, size: 14, color: p.success),
                                    const SizedBox(width: 4),
                                    Text(
                                      'مكتمل 🎉',
                                      style: AppTypography.badge(p.success),
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
                        style: AppTypography.meta(p.textSecondary),
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
                              backgroundColor: p.hairline,
                              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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
                  color: p.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
