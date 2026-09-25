import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../settings/presentation/pages/azkar_settings_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
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
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text('استعادة الأذكار الأصلية', style: TextStyle(fontFamily: 'Cairo')),
          ],
        ),
        content: const Text(
          'هل تريد استعادة جميع أذكار السنة النبوية الافتراضية؟\n\n'
          'سيتم استرجاع جميع الأذكار الأصلية مع الاحتفاظ بالأذكار التي قمت بإضافتها بنفسك.',
          style: TextStyle(fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AzkarBloc>().add(const RestoreDefaultAzkarEvent());
              AppSnackBar.showSuccess(context, 'تمت استعادة الأذكار الافتراضية بنجاح');
            },
            child: const Text('استعادة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Title
            Row(
              children: [
                const Icon(Icons.settings_outlined, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'خيارات وإعدادات الأذكار',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SECTION 1: الإعدادات العامة
            _buildSectionHeader('الإعدادات العامة'),
            _buildSettingTile(
              context: context,
              icon: Icons.settings_rounded,
              title: 'الإعدادات العامة للتطبيق',
              subtitle: 'المظهر، التوقيت، الصوت، واللغة',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, FadeSlidePageRoute(page: const SettingsPage()));
              },
              isDark: isDark,
            ),
            _buildSettingTile(
              context: context,
              icon: Icons.tune_rounded,
              title: 'إعدادات الأذكار والتنبيهات',
              subtitle: 'أوقات التذكير، الاهتزاز، وحجم الخط',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, FadeSlidePageRoute(page: const AzkarSettingsPage()));
              },
              isDark: isDark,
            ),

            const SizedBox(height: 16),

            // SECTION 2: البيانات (النسخ الاحتياطي والاسترجاع)
            _buildSectionHeader('البيانات'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: AppColors.accentGold),
                      SizedBox(width: 8),
                      Text(
                        'النسخ الاحتياطي والاسترجاع',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'احفظ أذكارك المخصصة واسترجعها عند الحاجة أو عند نقل الهاتف.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.accentGoldLight : AppColors.primary,
                            side: BorderSide(
                              color: isDark ? AppColors.accentGold : AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.file_upload_outlined, size: 16),
                          label: const Text(
                            'تصدير نسخة',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _handleExport(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.file_download_outlined, size: 16),
                          label: const Text(
                            'استيراد نسخة',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
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

            // SECTION 3: إجراءات أخرى
            _buildSectionHeader('إجراءات أخرى'),
            _buildSettingTile(
              context: context,
              icon: Icons.restart_alt_rounded,
              title: 'تصفير عدادات هذا القسم',
              subtitle: 'إعادة ضبط عداد ${currentCategory.titleArabic} إلى البداية',
              iconColor: Colors.blueGrey,
              onTap: () {
                Navigator.pop(context);
                context.read<AzkarBloc>().add(ResetCategoryProgressEvent(currentCategory));
                AppSnackBar.showInfo(context, 'تم تصفير عدادات ${currentCategory.titleArabic}');
              },
              isDark: isDark,
            ),
            _buildSettingTile(
              context: context,
              icon: Icons.restore_rounded,
              title: 'استعادة الأذكار الافتراضية',
              subtitle: 'إعادة أذكار السنة النبوية دون حذف أذكارك المخصصة',
              iconColor: AppColors.accentGold,
              onTap: () => _confirmRestoreDefaults(context),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
