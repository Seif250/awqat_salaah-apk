import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/custom_zikr_model.dart';

class AddCustomZikrDialog extends StatefulWidget {
  final Function(CustomZikr zikr) onAdd;

  const AddCustomZikrDialog({super.key, required this.onAdd});

  static Future<void> show(BuildContext context,
      {required Function(CustomZikr zikr) onAdd}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomZikrDialog(onAdd: onAdd),
    );
  }

  @override
  State<AddCustomZikrDialog> createState() => _AddCustomZikrDialogState();
}

class _AddCustomZikrDialogState extends State<AddCustomZikrDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  int _targetCount = 33;
  TimeOfDay? _reminderTime;
  bool _enableReminder = false;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 3, minute: 30),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
        _enableReminder = true;
      });
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final newZikr = CustomZikr(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        arabicText: _textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : _titleController.text.trim(),
        targetCount: _targetCount,
        reminderHour: _enableReminder ? _reminderTime?.hour : null,
        reminderMinute: _enableReminder ? _reminderTime?.minute : null,
        isReminderEnabled: _enableReminder && _reminderTime != null,
        createdAt: DateTime.now(),
      );

      widget.onAdd(newZikr);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star_outline_rounded, size: 22, color: p.accent),
                      const SizedBox(width: 8),
                      Text('إضافة ذكر مخصص', style: AppTypography.sectionHeader(p.textPrimary)),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: p.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الذكر أو اسم الورد',
                  hintText: 'مثال: ذكر قيام الليل، استغفار خاص...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.bookmark_border_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'يرجى كتابة عنوان الذكر'
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'نص الذكر (اختياري)',
                  hintText: 'اكتب نص الذكر أو الدعاء المأثور...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.format_quote_rounded),
                ),
              ),
              const SizedBox(height: 18),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('العدد المطلوب:', style: AppTypography.meta(p.textPrimary, weight: FontWeight.w700)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_targetCount ${_targetCount == 1 ? "مرة" : "مرات"}',
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
                      final isSelected = _targetCount == count;
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
                          if (selected) setState(() => _targetCount = count);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.cardElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('تفعيل تذكير يومي للذكر', style: AppTypography.rowTitle(p.textPrimary)),
                      subtitle: Text(
                        _reminderTime != null
                            ? 'موعد التذكير: ${_reminderTime!.format(context)}'
                            : 'اختر وقت التذكير (مثل وقت قيام الليل)',
                        style: AppTypography.label(p.textSecondary),
                      ),
                      value: _enableReminder,
                      activeThumbColor: p.primary,
                      onChanged: (val) {
                        setState(() => _enableReminder = val);
                        if (val && _reminderTime == null) {
                          _pickTime();
                        }
                      },
                    ),
                    if (_enableReminder)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: Icon(Icons.access_time_rounded, size: 18, color: p.accentText),
                          label: Text(
                            _reminderTime != null
                                ? 'تعديل الوقت (${_reminderTime!.format(context)})'
                                : 'تحديد الوقت',
                            style: AppTypography.meta(p.accentText, weight: FontWeight.w700),
                          ),
                          onPressed: _pickTime,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.add_task_rounded),
                label: Text(
                  'حفظ الذكر وإضافته',
                  style: AppTypography.body(p.onPrimary, weight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: p.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
