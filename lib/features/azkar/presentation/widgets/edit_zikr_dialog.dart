import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
  late bool _showOptionalFields;

  bool get _isEditing => widget.item != null;

  static const _starterTemplates = [
    (
      label: 'الصلاة على النبي ﷺ',
      title: 'الصلاة على النبي ﷺ',
      text: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      count: 10,
      reference: 'صحيح الجامع',
      reward: 'من صلّى عليّ حين يصبح وحين يمسي عشراً أدركته شفاعتي يوم القيامة.',
    ),
    (
      label: 'الاستغفار',
      title: 'الاستغفار',
      text: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
      count: 100,
      reference: 'متفق عليه',
      reward: 'مئة مرة في اليوم على هدي النبي ﷺ.',
    ),
    (
      label: 'سبحان الله وبحمده',
      title: 'التسبيح والتحميد',
      text: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
      count: 100,
      reference: 'متفق عليه',
      reward: 'حُطّت خطاياه وإن كانت مثل زبد البحر.',
    ),
    (
      label: 'الباقيات الصالحات',
      title: 'الباقيات الصالحات',
      text: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
      count: 33,
      reference: 'صحيح مسلم',
      reward: 'أحب الكلام إلى الله أربع.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item?.title ?? '');
    _textController =
        TextEditingController(text: widget.item?.arabicText ?? '');
    _targetCount = widget.item?.targetCount ?? 3;
    _countController = TextEditingController(text: _targetCount.toString());
    _rewardController = TextEditingController(text: widget.item?.reward ?? '');
    _referenceController =
        TextEditingController(text: widget.item?.reference ?? '');
    _showOptionalFields =
        (widget.item?.reward?.trim().isNotEmpty ?? false) ||
            (widget.item?.reference?.trim().isNotEmpty ?? false);

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
      final parsedCount =
          int.tryParse(_countController.text.trim()) ?? _targetCount;
      if (parsedCount <= 0) {
        AppSnackBar.showWarning(
            context, 'يرجى إدخال عدد تكرار صحيح أكبر من الصفر');
        return;
      }

      if (_selectedCategories.isEmpty) {
        AppSnackBar.showWarning(
            context, 'يرجى اختيار قسم واحد على الأقل للذكر');
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
    final p = context.palette;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: p.error),
            const SizedBox(width: 8),
            Text('حذف الذكر',
                style: AppTypography.sectionHeader(p.textPrimary)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${widget.item!.title}"؟\n\n'
          'سيتم إزالة هذا الذكر نهائياً من قائمتك المخصصة.',
          style: AppTypography.body(p.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: p.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete!();
            },
            child: Text('نعم، حذف',
                style:
                    AppTypography.meta(Colors.white, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
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
              const SizedBox(height: 12),

              if (!_isEditing) ...[
                Text(
                  'نماذج سريعة للتعبئة التلقائية',
                  style: AppTypography.label(
                    p.textSecondary,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _starterTemplates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final tpl = _starterTemplates[index];
                      return ActionChip(
                        avatar: Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: p.accentText,
                        ),
                        label: Text(
                          tpl.label,
                          style: AppTypography.label(
                            p.accentText,
                            weight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: p.primaryContainer.withValues(alpha: 0.7),
                        side: BorderSide(
                          color: p.primary.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onPressed: () {
                          setState(() {
                            _titleController.text = tpl.title;
                            _textController.text = tpl.text;
                            _targetCount = tpl.count;
                            _countController.text = tpl.count.toString();
                            _referenceController.text = tpl.reference;
                            _rewardController.text = tpl.reward;
                            _showOptionalFields = true;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 1. Title (اسم الذكر) - Required
              TextFormField(
                controller: _titleController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: 'اسم الذكر *',
                  hintText: 'مثال: سيد الاستغفار، الصلاة على النبي...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'يرجى كتابة اسم للذكر'
                    : null,
              ),
              const SizedBox(height: 12),

              // 2. Arabic Text (نص الذكر) - Required (hero input)
              TextFormField(
                controller: _textController,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    fontFamily: 'IBMPlexSansArabic', fontSize: 16, height: 1.6),
                decoration: InputDecoration(
                  labelText: 'نص الذكر أو الدعاء *',
                  hintText: 'اكتب نص الذكر كاملاً هنا...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 44),
                    child: Icon(Icons.format_quote_rounded),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'نص الذكر مطلوب'
                    : null,
              ),
              const SizedBox(height: 14),

              // 3. Repetition count (عدد التكرار)
              ZikrTargetCountChips(
                targetCount: _targetCount,
                controller: _countController,
                onCountChanged: (count) {
                  setState(() {
                    _targetCount = count;
                    final textVal = count.toString();
                    if (_countController.text != textVal) {
                      _countController.text = textVal;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              // 4. Category (القسم)
              ZikrCategorySelector(
                selectedCategories: _selectedCategories,
                onChanged: (updated) =>
                    setState(() => _selectedCategories = updated),
                isDark: isDark,
              ),
              const SizedBox(height: 10),

              // 5 & 6. Collapsible optional fields (المصدر وفضل الذكر)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: Icon(
                    _showOptionalFields
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.add_circle_outline_rounded,
                    size: 18,
                    color: p.accentText,
                  ),
                  label: Text(
                    _showOptionalFields
                        ? 'إخفاء المصدر والفضل'
                        : 'إضافة المصدر وفضل الذكر (اختياري)',
                    style: AppTypography.meta(
                      p.accentText,
                      weight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    setState(() => _showOptionalFields = !_showOptionalFields);
                  },
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _showOptionalFields
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _referenceController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: 'المصدر أو المرجع (اختياري)',
                          hintText: 'مثال: صحيح البخاري، الترمذي...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          prefixIcon: const Icon(Icons.menu_book_rounded),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _rewardController,
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: 'ملاحظة أو فضل الذكر (اختياري)',
                          hintText: 'مثال: يقال عند الاستيقاظ، حطت خطاياه...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

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
