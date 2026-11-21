import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../settings/presentation/pages/azkar_settings_page.dart';
import '../../data/models/azkar_item_model.dart';
import '../../data/repositories/azkar_repository.dart';
import '../../data/services/backup_service.dart';
import '../bloc/azkar_bloc.dart';
import '../bloc/azkar_event.dart';
import 'import_backup_preview_dialog.dart';

/// Modal bottom sheet replacing dense popup menu with a clear 3-section settings interface.
class AzkarSettingsSheet extends StatelessWidget {
  final AzkarCategory currentCategory;

  const AzkarSettingsSheet({
    super.key,
    required this.currentCategory,
  });

  static Future<void> show(BuildContext context, {required AzkarCategory currentCategory}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AzkarSettingsSheet(currentCategory: currentCategory),
    );
  }

  void _handleExport(BuildContext context) async {
    final repo = context.read<AzkarRepository>();
    final customItems = repo.getCustomAzkarItems();

    if (customItems.isEmpty) {
      Navigator.pop(context);
      AppSnackBar.showWarning(context, 'لا توجد أذكار مخصصة حالياً لتصديرها.');
      return;
    }

    Navigator.pop(context);
    await BackupService.exportBackup(context, customItems);
  }

  void _handleImport(BuildContext context) async {
    final repo = context.read<AzkarRepository>();
    final existingItems = repo.getCustomAzkarItems();

    try {
      final analysis = await BackupService.pickAndValidateBackup(existingItems: existingItems);
      if (analysis == null) return; // User cancelled

      if (!context.mounted) return;
      Navigator.pop(context); // close sheet

      // Show preview dialog
      await ImportBackupPreviewDialog.show(
        context,
        analysis: analysis,
        onConfirm: (replaceExisting) async {
          final count = await BackupService.executeImport(
            context: context,
            analysis: analysis,
            replaceExisting: replaceExisting,
          );

          if (!context.mounted) return;
          context.read<AzkarBloc>().add(const LoadAzkarEvent());

          if (replaceExisting) {
            AppSnackBar.showSuccess(context, 'تم استبدال واستيراد $count أذكار مخصصة بنجاح');
          } else {
            final skipped = analysis.duplicateItems.length;
            final message = skipped > 0
                ? 'تمت إضافة $count أذكار جديدة (تم تجاهل $skipped ذكر مكرر)'
                : 'تمت إضافة $count أذكار مخصصة بنجاح';
            AppSnackBar.showSuccess(context, message);
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackBar.showError(
          context,
          'تعذر استيراد النسخة الاحتياطية. الملف غير صالح أو غير متوافق مع هذا الإصدار من التطبيق.',
        );
      }
    }
  }

  void _confirmRestoreDefaults(BuildContext context) {
    final p = context.palette;
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.restore_rounded, color: p.accent),
            const SizedBox(width: 8),
            Text('استعادة الأذكار الأصلية', style: AppTypography.sectionHeader(p.textPrimary)),
          ],
        ),
        content: Text(
          'هل تريد استعادة جميع أذكار السنة النبوية الافتراضية؟\n\n'
          'سيتم استرجاع جميع الأذكار الأصلية مع الاحتفاظ بالأذكار التي قمت بإضافتها بنفسك.',
          style: AppTypography.body(p.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AzkarBloc>().add(const RestoreDefaultAzkarEvent());
              AppSnackBar.showSuccess(context, 'تمت استعادة الأذكار الافتراضية بنجاح');
            },
            child: Text('استعادة', style: AppTypography.meta(p.onPrimary, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: p.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Icon(Icons.settings_outlined, color: p.accentText, size: 22),
                const SizedBox(width: 8),
                Text('خيارات وإعدادات الأذكار', style: AppTypography.sectionHeader(p.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20, color: p.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildSectionHeader(p, 'الورد اليومي والعدادات'),
            _buildSettingTile(
              context: context,
              p: p,
              icon: Icons.restart_alt_rounded,
              title: 'تصفير عدادات هذا القسم',
              subtitle: 'إعادة ضبط عداد ${currentCategory.titleArabic} إلى البداية',
              iconColor: p.primary,
              onTap: () {
                Navigator.pop(context);
                context.read<AzkarBloc>().add(ResetCategoryProgressEvent(currentCategory));
                AppSnackBar.showInfo(context, 'تم تصفير عدادات ${currentCategory.titleArabic}');
              },
              isDark: isDark,
            ),
            _buildSettingTile(
              context: context,
              p: p,
              icon: Icons.restore_rounded,
              title: 'استعادة الأذكار الافتراضية',
              subtitle: 'إعادة أذكار السنة النبوية دون حذف أذكارك المخصصة',
              iconColor: p.accent,
              onTap: () => _confirmRestoreDefaults(context),
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            _buildSectionHeader(p, 'أذكاري المخصصة والنسخ الاحتياطي'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.cardElevated,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: p.accent),
                      const SizedBox(width: 8),
                      Text(
                        'النسخ الاحتياطي للأذكار المخصصة',
                        style: AppTypography.rowTitle(p.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'احفظ أذكارك المخصصة واسترجعها عند الحاجة أو عند نقل الهاتف إلى جهاز آخر.',
                    style: AppTypography.meta(p.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: p.accentText,
                            side: BorderSide(color: p.primary.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.file_upload_outlined, size: 16),
                          label: Text(
                            'تصدير أذكاري',
                            style: AppTypography.meta(p.accentText, weight: FontWeight.w700),
                          ),
                          onPressed: () => _handleExport(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.primary,
                            foregroundColor: p.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          label: Text(
                            'استيراد أذكار',
                            style: AppTypography.meta(p.onPrimary, weight: FontWeight.w700),
                          ),
                          onPressed: () => _handleImport(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildSectionHeader(p, 'التنبيهات والتخصيص'),
            _buildSettingTile(
              context: context,
              p: p,
              icon: Icons.notifications_active_outlined,
              title: 'مواعيد التنبيه بالورد اليومي',
              subtitle: 'تخصيص أوقات تذكير الصباح والمساء والنوم وقيام الليل',
              iconColor: p.primary,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, FadeSlidePageRoute(page: const AzkarSettingsPage()));
              },
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(WirdPalette p, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: AppTypography.label(p.accentText, weight: FontWeight.w700),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required WirdPalette p,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
  }) {
    final effectiveIcon = iconColor ?? p.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.hairline, width: 0.75),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: p.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: effectiveIcon, size: 20),
        ),
        title: Text(title, style: AppTypography.rowTitle(p.textPrimary)),
        subtitle: Text(subtitle, style: AppTypography.label(p.textSecondary)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: p.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
