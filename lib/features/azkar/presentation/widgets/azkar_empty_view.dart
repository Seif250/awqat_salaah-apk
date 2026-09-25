import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    final isCustom = category == AzkarCategory.custom;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Subtle Islamic book icon with gold accent
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 44,
                color: AppColors.accentGold,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              isCustom
                  ? 'لا توجد أذكار مخصصة حاليًا'
                  : 'لا توجد أذكار في هذا القسم',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              isCustom
                  ? 'أضف أذكارك الخاصة لتظهر هنا ويمكنك تعديلها أو حذفها في أي وقت.'
                  : 'يمكنك إضافة ذكر جديد إلى هذا القسم أو استعادة الأذكار الافتراضية الأصلية.',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Primary action button: + إضافة ذكر مخصص
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                isCustom ? '+ إضافة ذكر مخصص' : 'إضافة ذكر هنا',
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                elevation: 0,
              ),
              onPressed: onAdd,
            ),

            // Secondary action button
            if (isCustom && onRestoreBackup != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.file_download_outlined, size: 18, color: AppColors.accentGold),
                label: const Text(
                  'استيراد نسخة احتياطية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGold,
                  ),
                ),
                onPressed: onRestoreBackup,
              ),
            ] else if (!isCustom) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: const Text(
                  'استعادة الأذكار الافتراضية',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 12.5),
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
