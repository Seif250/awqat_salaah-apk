import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final p = context.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
              color: p.accent,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'تعديل الذكر' : 'إضافة ذكر جديد',
              style: AppTypography.sectionHeader(p.textPrimary),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.close_rounded, color: p.textSecondary),
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
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.cardElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category_outlined, size: 18, color: p.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أقسام وظهور الذكر (يمكنك اختيار أكثر من قسم):',
                  style: AppTypography.meta(p.textPrimary, weight: FontWeight.w700),
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
                  color: isSelected ? p.onPrimary : p.accent,
                ),
                label: Text(cat.titleArabic),
                labelStyle: AppTypography.label(
                  isSelected ? p.onPrimary : p.textPrimary,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                selectedColor: p.primary,
                backgroundColor: p.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? p.primary : p.hairline,
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
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'عدد التكرار:',
              style: AppTypography.meta(p.textPrimary, weight: FontWeight.w700),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: p.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$targetCount ${targetCount == 1 ? "مرة" : "مرات"}',
                style: AppTypography.badge(p.accentText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [1, 3, 7, 33, 70, 100].map((count) {
            final isSelected = targetCount == count;
            return ChoiceChip(
              label: Text('$count'),
              selected: isSelected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              selectedColor: p.primaryContainer,
              labelStyle: AppTypography.label(
                isSelected ? p.accentText : p.textPrimary,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (selected) {
                if (selected) onCountChanged(count);
              },
            );
          }).toList(),
        ),
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
    final p = context.palette;
    return Row(
      children: [
        if (showDelete && onDelete != null) ...[
          OutlinedButton.icon(
            icon: Icon(Icons.delete_outline_rounded, color: p.error),
            label: Text('حذف الذكر', style: AppTypography.meta(p.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: p.error),
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
            label: Text(
              isEditing ? 'حفظ التعديلات' : 'إضافة الذكر إلى الورد',
              style: AppTypography.body(p.onPrimary, weight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              elevation: 0,
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
