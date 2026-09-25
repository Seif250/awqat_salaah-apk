import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/backup_service.dart';

/// Modal dialog showing backup preview, duplicate count, and safe strategy options before importing.
class ImportBackupPreviewDialog extends StatefulWidget {
  final BackupAnalysisResult analysis;
  final VoidCallback onCancel;
  final Function(bool replaceExisting) onConfirm;

  const ImportBackupPreviewDialog({
    super.key,
    required this.analysis,
    required this.onCancel,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required BackupAnalysisResult analysis,
    required Function(bool replaceExisting) onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ImportBackupPreviewDialog(
        analysis: analysis,
        onCancel: () => Navigator.pop(ctx),
        onConfirm: (replace) {
          Navigator.pop(ctx);
          onConfirm(replace);
        },
      ),
    );
  }

  @override
  State<ImportBackupPreviewDialog> createState() => _ImportBackupPreviewDialogState();
}

class _ImportBackupPreviewDialogState extends State<ImportBackupPreviewDialog> {
  bool _replaceExisting = false; // MERGE is the safe default!

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalCount = widget.analysis.totalItems.length;
    final newCount = widget.analysis.newItems.length;
    final dupCount = widget.analysis.duplicateItems.length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.file_download_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'استيراد نسخة احتياطية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // Found Count Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تم العثور على:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.bookmark_added_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '$totalCount أذكار مخصصة في الملف',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (newCount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '$newCount أذكار جديدة ستتم إضافتها',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (dupCount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.accentGold),
                        const SizedBox(width: 8),
                        Text(
                          'وجدنا $dupCount ذكر موجودين بالفعل',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.5,
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Import Strategy Options
            const Text(
              'خطة الاستيراد:',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Option 1: Merge (Default & Recommended)
            InkWell(
              onTap: () => setState(() => _replaceExisting = false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: !_replaceExisting
                      ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_replaceExisting
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: !_replaceExisting ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _replaceExisting,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _replaceExisting = false),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'دمج البيانات (مستحسن)',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'الاحتفاظ بأذكارك الحالية وإضافة الأذكار الجديدة فقط بدون مسح أي شيء.',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Option 2: Replace All (Destructive - with clear warning)
            InkWell(
              onTap: () => setState(() => _replaceExisting = true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _replaceExisting
                      ? Colors.red.withValues(alpha: isDark ? 0.2 : 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _replaceExisting
                        ? Colors.red
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    width: _replaceExisting ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _replaceExisting,
                      activeColor: Colors.red,
                      onChanged: (val) => setState(() => _replaceExisting = true),
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'استبدال البيانات الحالية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'حذف جميع أذكارك المخصصة الحالية واستبدالها بما هو في الملف.',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_replaceExisting) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تنبيه: سيتم مسح أي أذكار مخصصة غير موجودة في هذا الملف.',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11.5, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _replaceExisting ? Colors.red : AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => widget.onConfirm(_replaceExisting),
          child: Text(
            _replaceExisting ? 'استبدال واستيراد' : 'استيراد',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
