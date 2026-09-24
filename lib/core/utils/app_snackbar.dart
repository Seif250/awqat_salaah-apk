import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Lightweight custom SnackBar with icon, rounded corners, and themed colors.
/// No external dependencies. Minimal overhead — just styled SnackBar.
class AppSnackBar {
  /// Shows a success SnackBar with a green accent
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Icons.check_circle_rounded, AppColors.primaryLight);
  }

  /// Shows an error SnackBar with a red accent
  static void showError(BuildContext context, String message) {
    _show(context, message, Icons.error_outline_rounded, Colors.red);
  }

  /// Shows a warning SnackBar with an orange accent
  static void showWarning(BuildContext context, String message) {
    _show(context, message, Icons.warning_amber_rounded, Colors.orange);
  }

  /// Shows an info SnackBar with a gold accent
  static void showInfo(BuildContext context, String message) {
    _show(context, message, Icons.info_outline_rounded, AppColors.accentGold);
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color accentColor,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 4,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
