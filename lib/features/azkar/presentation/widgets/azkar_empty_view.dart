import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/azkar_item_model.dart';

/// Empty state view shown when a category contains no azkar.
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined, size: 54, color: AppColors.accentGold),
            const SizedBox(height: 16),
            Text(
              'لا توجد أذكار في قسم "${category.titleArabic}" حالياً',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isCustom
                  ? 'يمكنك إضافة ذكر مخصص جديد أو استرجاع نسخة احتياطية سابقة محفوظة بصيغة JSON'
                  : 'يمكنك إضافة ذكر جديد إلى هذا القسم أو استعادة الأذكار الافتراضية الأصلية',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isCustom ? 'إضافة ذكر مخصص' : 'إضافة ذكر هنا'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onAdd,
                ),
                if (isCustom && onRestoreBackup != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_open_rounded, color: AppColors.accentGold),
                    label: const Text('استرجاع نسخة سابقة (JSON)'),
                    onPressed: onRestoreBackup,
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('استعادة الأذكار الافتراضية'),
                    onPressed: onRestore,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
