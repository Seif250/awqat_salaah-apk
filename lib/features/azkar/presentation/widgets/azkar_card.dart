import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../data/models/azkar_item_model.dart';
import 'azkar_card_components.dart';

class AzkarCard extends StatefulWidget {
  final AzkarItem item;
  final int itemIndex;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onToggleComplete;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final bool isReorderMode;
  final int? reorderIndex;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool isBookmarked;

  const AzkarCard({
    super.key,
    required this.item,
    this.itemIndex = 1,
    required this.onIncrement,
    this.onDecrement,
    required this.onToggleComplete,
    this.onBookmark,
    this.onShare,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
    this.isReorderMode = false,
    this.reorderIndex,
    this.onMoveUp,
    this.onMoveDown,
    this.isBookmarked = false,
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
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.16), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.16, end: 0.96), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 30),
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
    if (widget.item.currentCount != oldWidget.item.currentCount) {
      _bounceController.forward(from: 0);
    }
    if (!_wasCompleted && widget.item.isCompleted) {
      HapticFeedback.heavyImpact();
    }
    _wasCompleted = widget.item.isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = widget.item.isCompleted;

    return Semantics(
      button: true,
      label: '${widget.item.title}، المقروء ${widget.item.currentCount} من ${widget.item.targetCount}، ${isCompleted ? "مكتمل بحمد الله" : "انقر للتسبيح والزيادة"}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppDesignSystem.cardDecoration(
          isDark: isDark,
          isCompleted: isCompleted,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusCard),
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
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusCard),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Number Circle, Title, More & Share actions
                    AzkarCardHeader(
                      item: widget.item,
                      itemIndex: widget.itemIndex,
                      isCompleted: isCompleted,
                      isDark: isDark,
                      isReorderMode: widget.isReorderMode,
                      reorderIndex: widget.reorderIndex,
                      onMoveUp: widget.onMoveUp,
                      onMoveDown: widget.onMoveDown,
                      onEdit: widget.onEdit,
                      onDelete: widget.onDelete,
                      onBookmark: widget.onBookmark,
                      onShare: widget.onShare,
                      isBookmarked: widget.isBookmarked,
                    ),

                    const SizedBox(height: 12),

                    // Body: Arabic Dhikr Text Container + Virtue "من فضلها" Container
                    AzkarCardBody(
                      item: widget.item,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    // Footer: "حفظ" Bookmark pill button + [-] Count [+] interactive controls
                    AzkarCardFooter(
                      item: widget.item,
                      isCompleted: isCompleted,
                      isDark: isDark,
                      isReorderMode: widget.isReorderMode,
                      scaleAnimation: _scaleAnimation,
                      onIncrement: widget.onIncrement,
                      onDecrement: widget.onDecrement ?? () {},
                      onBookmark: widget.onBookmark ?? () {},
                      isBookmarked: widget.isBookmarked,
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
