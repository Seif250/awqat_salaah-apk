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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: p.hairline,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: p.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isEditing
                        ? Icons.edit_note_rounded
                        : Icons.add_circle_outline_rounded,
                    color: p.accentText,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
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
        ),
      ],
    );
  }
}

/// Multi-category horizontal pill selector for Azkar.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, size: 17, color: p.accentText),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'أقسام ظهور الذكر',
                style: AppTypography.meta(p.textPrimary, weight: FontWeight.w700),
              ),
            ),
            Text(
              '${selectedCategories.length} محدد',
              style: AppTypography.label(p.accentText, weight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AzkarCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final cat = AzkarCategory.values[index];
              final isSelected = selectedCategories.contains(cat);
              return FilterChip(
                selected: isSelected,
                avatar: Icon(
                  cat.categoryIcon,
                  size: 15,
                  color: isSelected ? p.onPrimary : p.accentText,
                ),
                label: Text(cat.titleArabic),
                labelStyle: AppTypography.label(
                  isSelected ? p.onPrimary : p.textPrimary,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                selectedColor: p.primary,
                backgroundColor: p.cardElevated,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
                  } else if (updated.length > 1) {
                    updated.remove(cat);
                    onChanged(updated);
                  } else {
                    AppSnackBar.showWarning(
                      context,
                      'يجب أن ينتمي الذكر لقسم واحد على الأقل',
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Target repetition selector with tactile stepper + quick preset pills.
class ZikrTargetCountChips extends StatelessWidget {
  final int targetCount;
  final ValueChanged<int> onCountChanged;
  final TextEditingController? controller;

  const ZikrTargetCountChips({
    super.key,
    required this.targetCount,
    required this.onCountChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'عدد التكرار',
                style: AppTypography.meta(p.textPrimary, weight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: p.cardElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepperButton(
                    icon: Icons.remove_rounded,
                    enabled: targetCount > 1,
                    onTap: () => onCountChanged((targetCount - 1).clamp(1, 9999)),
                  ),
                  if (controller != null)
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        style: AppTypography.timeValue(
                          p.textPrimary,
                          size: 16,
                          weight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                        ),
                        validator: (val) {
                          final n = int.tryParse(val?.trim() ?? '');
                          if (n == null || n <= 0) return '≥ ١';
                          return null;
                        },
                        onChanged: (val) {
                          final n = int.tryParse(val.trim());
                          if (n != null && n > 0) {
                            onCountChanged(n);
                          }
                        },
                      ),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(minWidth: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      child: Text(
                        '$targetCount',
                        style: AppTypography.timeValue(
                          p.textPrimary,
                          size: 16,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  _StepperButton(
                    icon: Icons.add_rounded,
                    enabled: targetCount < 9999,
                    onTap: () => onCountChanged((targetCount + 1).clamp(1, 9999)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [1, 3, 7, 33, 70, 100].map((count) {
            final isSelected = targetCount == count;
            return ChoiceChip(
              label: Text('$count'),
              selected: isSelected,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              selectedColor: p.primaryContainer,
              backgroundColor: p.cardElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected ? p.primary : p.hairline,
                ),
              ),
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

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? p.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? p.accentText : p.textSecondary.withValues(alpha: 0.4),
        ),
      ),
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
