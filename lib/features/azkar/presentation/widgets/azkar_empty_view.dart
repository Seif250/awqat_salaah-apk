import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/azkar_item_model.dart';

/// Calm, centered empty state view for Azkar categories.
class AzkarEmptyView extends StatelessWidget {
  final AzkarCategory category;
  final VoidCallback onAdd;
  final VoidCallback onRestore;
  final VoidCallback? onRestoreBackup;

  const AzkarEmptyView({
    super.key,
    required this.category,
    required this.onAdd,
    required this.onRestore,
    this.onRestoreBackup,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isCustom = category == AzkarCategory.custom;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 42,
                color: p.accent,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              isCustom
                  ? 'لا توجد أذكار مخصصة حاليًا'
                  : 'لا توجد أذكار في هذا القسم',
              style: AppTypography.sectionHeader(p.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              isCustom
                  ? 'أضف أذكارك الخاصة لتظهر هنا ويمكنك تعديلها أو حذفها في أي وقت.'
                  : 'يمكنك إضافة ذكر جديد إلى هذا القسم أو استعادة الأذكار الافتراضية الأصلية.',
              style: AppTypography.meta(p.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                isCustom ? '+ إضافة ذكر مخصص' : 'إضافة ذكر هنا',
                style: AppTypography.meta(p.onPrimary, weight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                elevation: 0,
              ),
              onPressed: onAdd,
            ),

            if (isCustom && onRestoreBackup != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: Icon(Icons.file_download_outlined, size: 18, color: p.accentText),
                label: Text(
                  'استيراد نسخة احتياطية',
                  style: AppTypography.meta(p.accentText, weight: FontWeight.w600),
                ),
                onPressed: onRestoreBackup,
              ),
            ] else if (!isCustom) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: Icon(Icons.restore_rounded, size: 18, color: p.accentText),
                label: Text(
                  'استعادة الأذكار الافتراضية',
                  style: AppTypography.meta(p.accentText),
                ),
                onPressed: onRestore,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
