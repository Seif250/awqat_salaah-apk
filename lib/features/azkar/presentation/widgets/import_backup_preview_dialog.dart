import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final p = context.palette;

    final totalCount = widget.analysis.totalItems.length;
    final newCount = widget.analysis.newItems.length;
    final dupCount = widget.analysis.duplicateItems.length;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: p.surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.file_download_outlined, color: p.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('استيراد نسخة احتياطية', style: AppTypography.sectionHeader(p.textPrimary)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.cardElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تم العثور على:', style: AppTypography.label(p.textSecondary, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.bookmark_added_rounded, size: 18, color: p.primary),
                      const SizedBox(width: 8),
                      Text('$totalCount أذكار مخصصة في الملف', style: AppTypography.rowTitle(p.textPrimary)),
                    ],
                  ),
                  if (newCount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.add_circle_outline_rounded, size: 18, color: p.success),
                        const SizedBox(width: 8),
                        Text(
                          '$newCount أذكار جديدة ستتم إضافتها',
                          style: AppTypography.meta(p.textPrimary, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  if (dupCount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: p.accent),
                        const SizedBox(width: 8),
                        Text(
                          'وجدنا $dupCount ذكر موجودين بالفعل',
                          style: AppTypography.meta(p.accentText, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text('خطة الاستيراد:', style: AppTypography.rowTitle(p.textPrimary)),
            const SizedBox(height: 8),

            InkWell(
              onTap: () => setState(() => _replaceExisting = false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: !_replaceExisting ? p.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_replaceExisting ? p.primary : p.hairline,
                    width: !_replaceExisting ? 1.5 : 0.75,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _replaceExisting,
                      activeColor: p.primary,
                      onChanged: (val) => setState(() => _replaceExisting = false),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('دمج البيانات (مستحسن)', style: AppTypography.meta(p.textPrimary, weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            'الاحتفاظ بأذكارك الحالية وإضافة الأذكار الجديدة فقط بدون مسح أي شيء.',
                            style: AppTypography.label(p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: () => setState(() => _replaceExisting = true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _replaceExisting ? p.error.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _replaceExisting ? p.error : p.hairline,
                    width: _replaceExisting ? 1.5 : 0.75,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _replaceExisting,
                      activeColor: p.error,
                      onChanged: (val) => setState(() => _replaceExisting = true),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('استبدال البيانات الحالية', style: AppTypography.meta(p.error, weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            'حذف جميع أذكارك المخصصة الحالية واستبدالها بما هو في الملف.',
                            style: AppTypography.label(p.textSecondary),
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
                  color: p.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: p.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: p.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تنبيه: سيتم مسح أي أذكار مخصصة غير موجودة في هذا الملف.',
                        style: AppTypography.label(p.error),
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
          child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _replaceExisting ? p.error : p.primary,
            foregroundColor: p.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => widget.onConfirm(_replaceExisting),
          child: Text(
            _replaceExisting ? 'استبدال واستيراد' : 'استيراد',
            style: AppTypography.meta(Colors.white, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
