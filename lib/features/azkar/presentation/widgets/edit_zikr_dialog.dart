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
  late final TextEditingController _countController;
  late final TextEditingController _rewardController;
  late final TextEditingController _referenceController;
  late int _targetCount;
  late Set<AzkarCategory> _selectedCategories;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _textController = TextEditingController(text: widget.item?.arabicText ?? '');
    _targetCount = widget.item?.targetCount ?? 3;
    _countController = TextEditingController(text: _targetCount.toString());
    _rewardController = TextEditingController(text: widget.item?.reward ?? '');
    _referenceController = TextEditingController(text: widget.item?.reference ?? '');

    final initialCat = widget.initialCategory ?? AzkarCategory.custom;
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
    _countController.dispose();
    _rewardController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final parsedCount = int.tryParse(_countController.text.trim()) ?? _targetCount;
      if (parsedCount <= 0) {
        AppSnackBar.showWarning(context, 'يرجى إدخال عدد تكرار صحيح أكبر من الصفر');
        return;
      }

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
              targetCount: parsedCount,
            )
          : AzkarItem(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              title: _titleController.text.trim(),
              arabicText: _textController.text.trim(),
              category: primaryCategory,
              categories: categoryList,
              targetCount: parsedCount,
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
            Text('حذف الذكر', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${widget.item!.title}"؟\n\n'
          'سيتم إزالة هذا الذكر نهائياً من قائمتك المخصصة.',
          style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete!();
            },
            child: const Text('نعم، حذف', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
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

              // 1. Title (اسم الذكر) - Required
              TextFormField(
                controller: _titleController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'اسم الذكر *',
                  hintText: 'مثال: سيد الاستغفار، الصلاة على النبي...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'يرجى كتابة اسم للذكر'
                    : null,
              ),
              const SizedBox(height: 14),

              // 2. Arabic Text (نص الذكر) - Required (hero input)
              TextFormField(
                controller: _textController,
                maxLines: 5,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.6),
                decoration: InputDecoration(
                  labelText: 'نص الذكر أو الدعاء *',
                  hintText: 'اكتب نص الذكر كاملاً هنا...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.format_quote_rounded),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'نص الذكر مطلوب'
                    : null,
              ),
              const SizedBox(height: 16),

              // 3. Repetition count (عدد التكرار)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ZikrTargetCountChips(
                      targetCount: _targetCount,
                      onCountChanged: (count) {
                        setState(() {
                          _targetCount = count;
                          _countController.text = count.toString();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'العدد المحدد',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (val) {
                        final n = int.tryParse(val?.trim() ?? '');
                        if (n == null || n <= 0) return 'عدد موجب';
                        return null;
                      },
                      onChanged: (val) {
                        final n = int.tryParse(val.trim());
                        if (n != null && n > 0) {
                          setState(() => _targetCount = n);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Category (القسم)
              ZikrCategorySelector(
                selectedCategories: _selectedCategories,
                onChanged: (updated) => setState(() => _selectedCategories = updated),
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              // 5. Source / Reference (المصدر / المرجع) - Optional
              TextFormField(
                controller: _referenceController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'المصدر أو المرجع (اختياري)',
                  hintText: 'مثال: صحيح البخاري، الترمذي...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.menu_book_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // 6. Note (ملاحظة أو فضل الذكر) - Optional
              TextFormField(
                controller: _rewardController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'ملاحظة أو فضل الذكر (اختياري)',
                  hintText: 'مثال: يقال عند الاستيقاظ، حطت خطاياه...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.note_alt_outlined),
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
