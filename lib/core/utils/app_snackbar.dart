import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Lightweight custom SnackBar with icon, rounded corners, and themed colors.
/// No external dependencies. Minimal overhead — just styled SnackBar.
class AppSnackBar {
  static OverlayEntry? _currentEntry;

  /// Shows a success toast with a green accent
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      Icons.check_circle_rounded,
      const Color(0xFF10B981),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows an error toast with a red accent
  static void showError(BuildContext context, String message) {
    _show(context, message, Icons.error_rounded, const Color(0xFFEF4444));
  }

  /// Shows a warning toast with an amber/orange accent
  static void showWarning(BuildContext context, String message) {
    _show(context, message, Icons.warning_rounded, const Color(0xFFF59E0B));
  }

  /// Shows an info toast with a warm gold accent
  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      Icons.info_rounded,
      AppColors.accentGold,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color accentColor, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    // Dismiss existing toast immediately if active
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Fallback to standard SnackBar if overlay not found
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        icon: icon,
        accentColor: accentColor,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          if (_currentEntry == entry) {
            entry.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.accentColor,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Auto dismiss after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 14,
      left: 16,
      right: 16,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xF21C2421)
                          : const Color(0xF7FFFFFF),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : widget.accentColor.withValues(alpha: 0.22),
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: widget.accentColor.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            widget.icon,
                            size: 16,
                            color: widget.accentColor,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        if (widget.actionLabel != null && widget.onAction != null) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              _dismiss();
                              widget.onAction!();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                widget.actionLabel!,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: widget.accentColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
