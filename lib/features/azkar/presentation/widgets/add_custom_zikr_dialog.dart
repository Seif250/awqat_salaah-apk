import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_outline_rounded,
                          size: 22, color: AppColors.accentGold),
                      const SizedBox(width: 8),
                      Text(
                        'إضافة ذكر مخصص',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان الذكر أو اسم الورد',
                  hintText: 'مثال: ذكر قيام الليل، استغفار خاص...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.bookmark_border_rounded),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'يرجى كتابة عنوان الذكر'
                    : null,
              ),
              const SizedBox(height: 14),

              // Arabic Text Field
              TextFormField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'نص الذكر (اختياري)',
                  hintText: 'اكتب نص الذكر أو الدعاء المأثور...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.format_quote_rounded),
                ),
              ),
              const SizedBox(height: 18),

              // Target Repetitions
              Row(
                children: [
                  const Text('العدد المطلوب: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  ...[1, 3, 33, 70, 100].map((count) {
                    final isSelected = _targetCount == count;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Text('$count'),
                        selected: isSelected,
                        selectedColor:
                            AppColors.accentGold.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.accentGold : null,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _targetCount = count);
                        },
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Reminder Time Option
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('تفعيل تذكير يومي للذكر',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        _reminderTime != null
                            ? 'موعد التذكير: ${_reminderTime!.format(context)}'
                            : 'اختر وقت التذكير (مثل وقت قيام الليل)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _enableReminder,
                      activeThumbColor: AppColors.primaryLight,
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
                          icon: const Icon(Icons.access_time_rounded, size: 18),
                          label: Text(
                            _reminderTime != null
                                ? 'تعديل الوقت (${_reminderTime!.format(context)})'
                                : 'تحديد الوقت',
                            style: const TextStyle(color: AppColors.accentGold),
                          ),
                          onPressed: _pickTime,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('حفظ الذكر وإضافته'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
