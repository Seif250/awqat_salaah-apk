import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';

class NotificationOffsetsDialog {
  static String formatNotificationOffsets(List<int> offsets) {
    if (offsets.isEmpty) return 'عند دخول وقت الصلاة';
    final labels = <String>[];
    for (final o in (offsets.toSet().toList()..sort())) {
      if (o == 0) {
        labels.add('عند دخول الوقت');
      } else if (o < 0) {
        labels.add('قبل الأذان بـ ${-o} د');
      } else {
        labels.add('بعد الأذان بـ $o د');
      }
    }
    return labels.join(' • ');
  }

  static void show(BuildContext context, List<int> currentOffsets) {
    final selected = Set<int>.from(currentOffsets);
    if (selected.isEmpty) selected.add(0);

    final standardOptions = [
      const MapEntry(-15, 'قبل الأذان بـ 15 دقيقة'),
      const MapEntry(-10, 'قبل الأذان بـ 10 دقائق'),
      const MapEntry(-5, 'قبل الأذان بـ 5 دقائق'),
      const MapEntry(0, 'عند دخول وقت الصلاة (الأذان)'),
      const MapEntry(5, 'بعد الأذان بـ 5 دقائق'),
      const MapEntry(10, 'بعد الأذان بـ 10 دقائق'),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final p = context.palette;
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.timer_outlined, color: p.accent),
                  const SizedBox(width: 8),
                  Text('مواعيد تنبيه الصلاة', style: AppTypography.sectionHeader(p.textPrimary)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'يمكنك اختيار أكثر من موعد تنبيه للصلاة الواحدة:',
                        style: AppTypography.meta(p.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ...standardOptions.map((entry) {
                        final isChecked = selected.contains(entry.key);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.value,
                            style: AppTypography.body(
                              isChecked ? p.accentText : p.textPrimary,
                              weight: isChecked ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                          value: isChecked,
                          activeColor: p.primary,
                          onChanged: (bool? val) {
                            setDialogState(() {
                              if (val == true) {
                                selected.add(entry.key);
                              } else {
                                if (selected.length > 1) {
                                  selected.remove(entry.key);
                                }
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.onPrimary),
                  onPressed: () {
                    final result = selected.toList()..sort();
                    context.read<SettingsBloc>().add(ChangeNotificationOffsetsEvent(result));
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
