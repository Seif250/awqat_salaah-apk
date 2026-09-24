import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../data/models/azkar_item_model.dart';
import '../utils/azkar_ui_helpers.dart';

/// Header for the Edit / Add Zikr bottom sheet.
class EditZikrHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onClose;

  const EditZikrHeader({
    super.key,
    required this.isEditing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
              color: AppColors.accentGold,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'تعديل الذكر' : 'إضافة ذكر جديد',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// Multi-category chip selector for Azkar.
class ZikrCategorySelector extends StatelessWidget {
  final Set<AzkarCategory> selectedCategories;
  final ValueChanged<Set<AzkarCategory>> onChanged;
  final bool isDark;

  const ZikrCategorySelector({
    super.key,
    required this.selectedCategories,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category_outlined, size: 18, color: AppColors.accentGold),
              const SizedBox(width: 8),
              Text(
                'أقسام وظهور الذكر (يمكنك اختيار أكثر من قسم):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: isDark ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AzkarCategory.values.map((cat) {
              final isSelected = selectedCategories.contains(cat);
              return FilterChip(
                selected: isSelected,
                avatar: Icon(
                  cat.categoryIcon,
                  size: 15,
                  color: isSelected ? Colors.white : AppColors.accentGold,
                ),
                label: Text(cat.titleArabic),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
                selectedColor: AppColors.primary,
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  final updated = Set<AzkarCategory>.from(selectedCategories);
                  if (selected) {
                    updated.add(cat);
                    onChanged(updated);
                  } else {
                    if (updated.length > 1) {
                      updated.remove(cat);
                      onChanged(updated);
                    } else {
                      AppSnackBar.showWarning(context, 'يجب أن ينتمي الذكر لقسم واحد على الأقل');
                    }
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Target repetition selector using quick choice chips.
class ZikrTargetCountChips extends StatelessWidget {
  final int targetCount;
  final ValueChanged<int> onCountChanged;

  const ZikrTargetCountChips({
    super.key,
    required this.targetCount,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'عدد التكرار: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const Spacer(),
        ...[1, 3, 7, 33, 70, 100].map((count) {
          final isSelected = targetCount == count;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: ChoiceChip(
              label: Text('$count'),
              selected: isSelected,
              selectedColor: AppColors.accentGold.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.accentGold : null,
              ),
              onSelected: (selected) {
                if (selected) onCountChanged(count);
              },
            ),
          );
        }),
      ],
    );
  }
}

/// Action buttons for saving edits / adding zikr or deleting.
class EditZikrActionButtons extends StatelessWidget {
  final bool isEditing;
  final bool showDelete;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const EditZikrActionButtons({
    super.key,
    required this.isEditing,
    required this.showDelete,
    required this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showDelete && onDelete != null) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            label: const Text('حذف الذكر', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onDelete,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
            label: Text(isEditing ? 'حفظ التعديلات' : 'إضافة الذكر إلى الورد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}
