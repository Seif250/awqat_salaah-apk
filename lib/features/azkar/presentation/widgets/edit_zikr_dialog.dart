import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../data/models/azkar_item_model.dart';
import 'edit_zikr_form_fields.dart';

class EditZikrDialog extends StatefulWidget {
  final AzkarItem? item;
  final AzkarCategory? initialCategory;
  final Function(AzkarItem item) onSave;
  final VoidCallback? onDelete;

  const EditZikrDialog({
    super.key,
    this.item,
    this.initialCategory,
    required this.onSave,
    this.onDelete,
  });

  /// Show dialog to edit an existing dhikr (system or custom)
  static Future<void> show(
    BuildContext context, {
    required AzkarItem item,
    required Function(AzkarItem updated) onSave,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditZikrDialog(
        item: item,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  /// Show dialog to add a brand new dhikr into any category
  static Future<void> showAdd(
    BuildContext context, {
    AzkarCategory? initialCategory,
    required Function(AzkarItem newItem) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditZikrDialog(
        initialCategory: initialCategory,
        onSave: onAdd,
      ),
    );
  }

  @override
  State<EditZikrDialog> createState() => _EditZikrDialogState();
}

class _EditZikrDialogState extends State<EditZikrDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  late final TextEditingController _rewardController;
  late final TextEditingController _referenceController;
  late int _targetCount;
  late Set<AzkarCategory> _selectedCategories;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _textController =
        TextEditingController(text: widget.item?.arabicText ?? '');
    _rewardController = TextEditingController(text: widget.item?.reward ?? '');
    _referenceController =
        TextEditingController(text: widget.item?.reference ?? '');
    _targetCount = widget.item?.targetCount ?? 3;

    final initialCat = widget.initialCategory ?? AzkarCategory.morning;
    if (widget.item != null) {
      _selectedCategories = widget.item!.effectiveCategories.toSet();
      if (_selectedCategories.isEmpty) {
        _selectedCategories = {widget.item!.category};
      }
    } else {
      _selectedCategories = {initialCat};
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _rewardController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategories.isEmpty) {
        AppSnackBar.showWarning(context, 'يرجى اختيار قسم واحد على الأقل للذكر');
        return;
      }

      final primaryCategory = _selectedCategories.first;
      final categoryList = _selectedCategories.toList();

      final item = _isEditing
          ? widget.item!.copyWith(
              title: _titleController.text.trim(),
              arabicText: _textController.text.trim(),
              category: primaryCategory,
              categories: categoryList,
              reward: _rewardController.text.trim().isNotEmpty
                  ? _rewardController.text.trim()
                  : null,
              reference: _referenceController.text.trim().isNotEmpty
                  ? _referenceController.text.trim()
                  : null,
              targetCount: _targetCount,
            )
          : AzkarItem(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              title: _titleController.text.trim(),
              arabicText: _textController.text.trim(),
              category: primaryCategory,
              categories: categoryList,
              targetCount: _targetCount,
              reward: _rewardController.text.trim().isNotEmpty
                  ? _rewardController.text.trim()
                  : null,
              reference: _referenceController.text.trim().isNotEmpty
                  ? _referenceController.text.trim()
                  : null,
              isCustom: true,
            );

      widget.onSave(item);
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    if (widget.item == null || widget.onDelete == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('حذف الذكر'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${widget.item!.title}" من الأذكار؟\n\n'
          'ملاحظة: يمكنك في أي وقت استعادة الأذكار الافتراضية الأصلية من زر الخيارات بالأعلى.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete!();
            },
            child: const Text('نعم، حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              EditZikrHeader(
                isEditing: _isEditing,
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الذكر',
                  hintText: 'مثال: سيد الاستغفار، تسبيح، دعاء...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'يرجى كتابة عنوان للذكر'
                    : null,
              ),
              const SizedBox(height: 14),

              // Multi-Category Selector Card
              ZikrCategorySelector(
                selectedCategories: _selectedCategories,
                onChanged: (updated) => setState(() => _selectedCategories = updated),
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              // Arabic Text
              TextFormField(
                controller: _textController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'نص الذكر أو الدعاء',
                  hintText: 'اكتب نص الذكر النبوي أو الدعاء كاملاً...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.format_quote_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'نص الذكر مطلوب'
                    : null,
              ),
              const SizedBox(height: 16),

              // Target Repetitions Chips
              ZikrTargetCountChips(
                targetCount: _targetCount,
                onCountChanged: (count) => setState(() => _targetCount = count),
              ),
              const SizedBox(height: 14),

              // Virtue & Reference
              TextFormField(
                controller: _rewardController,
                decoration: InputDecoration(
                  labelText: 'الفضل والثواب (اختياري)',
                  hintText: 'مثال: حطت خطاياه، كفته من كل شيء، من أهل الجنة...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.stars_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: 'المصدر أو الحديث (اختياري)',
                  hintText: 'مثال: صحيح البخاري، مسلم، الترمذي...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.menu_book_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons: Save & Delete
              EditZikrActionButtons(
                isEditing: _isEditing,
                showDelete: _isEditing && widget.onDelete != null,
                onSave: _save,
                onDelete: _confirmDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
