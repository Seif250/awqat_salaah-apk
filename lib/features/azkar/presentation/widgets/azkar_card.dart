import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';
import 'azkar_card_components.dart';

class AzkarCard extends StatefulWidget {
  final AzkarItem item;
  final VoidCallback onIncrement;
  final VoidCallback onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;
  final bool isReorderMode;
  final int? reorderIndex;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const AzkarCard({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onToggleComplete,
    this.onEdit,
    this.onLongPress,
    this.isReorderMode = false,
    this.reorderIndex,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  State<AzkarCard> createState() => _AzkarCardState();
}

class _AzkarCardState extends State<AzkarCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;
  bool _wasCompleted = false;

  @override
  void initState() {
    super.initState();
    _wasCompleted = widget.item.isCompleted;
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AzkarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bounce the counter when count changes
    if (widget.item.currentCount != oldWidget.item.currentCount) {
      _bounceController.forward(from: 0);
    }
    // Detect completion transition
    if (!_wasCompleted && widget.item.isCompleted) {
      HapticFeedback.heavyImpact();
    }
    _wasCompleted = widget.item.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = widget.item.isCompleted;

    final double progress = widget.item.targetCount > 0
        ? (widget.item.currentCount / widget.item.targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Semantics(
      button: true,
      label: '${widget.item.title}، المقروء ${widget.item.currentCount} من ${widget.item.targetCount}، ${isCompleted ? "مكتمل بحمد الله" : "انقر للتسبيح والزيادة"}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isCompleted
              ? (isDark ? const Color(0xFF0F2218) : const Color(0xFFF3F9F5))
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isCompleted ? 1.0 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.025),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isReorderMode
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      widget.onIncrement();
                    },
              onLongPress: widget.onLongPress != null
                  ? () {
                      HapticFeedback.mediumImpact();
                      widget.onLongPress!();
                    }
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Drag handle, title, repetition badge, edit button / reorder arrows
                    AzkarCardHeader(
                      item: widget.item,
                      isCompleted: isCompleted,
                      isDark: isDark,
                      isReorderMode: widget.isReorderMode,
                      reorderIndex: widget.reorderIndex,
                      onMoveUp: widget.onMoveUp,
                      onMoveDown: widget.onMoveDown,
                      onEdit: widget.onEdit,
                    ),
                    const SizedBox(height: 10),

                    // Body: Arabic Dhikr text (Hero) and reward / reference
                    AzkarCardBody(
                      item: widget.item,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    // Footer: Animated progress bar, counter pill, complete toggle
                    AzkarCardProgressFooter(
                      item: widget.item,
                      isCompleted: isCompleted,
                      isDark: isDark,
                      isReorderMode: widget.isReorderMode,
                      progress: progress,
                      scaleAnimation: _scaleAnimation,
                      onIncrement: widget.onIncrement,
                      onToggleComplete: widget.onToggleComplete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

