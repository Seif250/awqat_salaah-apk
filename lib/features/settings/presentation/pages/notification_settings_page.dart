import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/notification_service.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  String _getSoundDisplayName(String soundType) {
    switch (soundType) {
      case AppConstants.soundTypeFull:
        return 'الأذان كامل';
      case AppConstants.soundTypeTakbeer:
        return 'الله أكبر الله أكبر (تكبيرات)';
      case AppConstants.soundTypeHayya:
      default:
        return 'حي على الصلاة (مختصر)';
    }
  }

  void _showAdhanSoundDialog(BuildContext context, String currentSoundType) {
    String selected = currentSoundType;
    String? currentlyPlaying;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final options = [
              {
                'key': AppConstants.soundTypeFull,
                'title': 'الأذان كامل',
                'subtitle': 'صوت الأذان كاملاً مع الترديد والدعاء',
              },
              {
                'key': AppConstants.soundTypeHayya,
                'title': 'حي على الصلاة',
                'subtitle': 'صوت الأذان المختصر المعتاد',
              },
              {
                'key': AppConstants.soundTypeTakbeer,
                'title': 'الله أكبر الله أكبر',
                'subtitle': 'تكبيرات دخول وقت الصلاة',
              },
            ];

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.music_note_rounded, color: AppColors.accentGold),
                  SizedBox(width: 8),
                  Text('اختيار صوت الأذان'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'اختر صوت الأذان المفضل مع إمكانية الاستماع للتجربة قبل الاختيار:',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ...options.map((opt) {
                      final key = opt['key']!;
                      final isSelected = selected == key;
                      final isPlaying = currentlyPlaying == key;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accentGold
                                : Colors.grey.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                          color: isSelected
                              ? AppColors.accentGold.withValues(alpha: 0.08)
                              : null,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: Radio<String>(
                            value: key,
                            groupValue: selected,
                            activeColor: AppColors.accentGold,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selected = val);
                              }
                            },
                          ),
                          title: Text(
                            opt['title']!,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? AppColors.accentGold : null,
                            ),
                          ),
                          subtitle: Text(opt['subtitle']!, style: const TextStyle(fontSize: 12)),
                          trailing: IconButton.filledTonal(
                            tooltip: isPlaying ? 'إيقاف' : 'استماع',
                            icon: Icon(
                              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              color: isPlaying ? Colors.red : AppColors.accentGold,
                              size: 22,
                            ),
                            onPressed: () async {
                              if (isPlaying) {
                                await NotificationService().stopAudioPreview();
                                setDialogState(() => currentlyPlaying = null);
                              } else {
                                await NotificationService().playAudioPreview(key);
                                setDialogState(() => currentlyPlaying = key);
                              }
                            },
                          ),
                          onTap: () {
                            setDialogState(() => selected = key);
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    NotificationService().stopAudioPreview();
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accentGold),
                  onPressed: () {
                    NotificationService().stopAudioPreview();
                    context.read<SettingsBloc>().add(ChangeNotificationSoundTypeEvent(selected));
                    context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم تعيين صوت الأذان: ${_getSoundDisplayName(selected)}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      NotificationService().stopAudioPreview();
    });
  }

  String _formatNotificationOffsets(List<int> offsets) {
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

  void _showNotificationOffsetsDialog(BuildContext context, List<int> currentOffsets) {
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
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: AppColors.accentGold),
                  SizedBox(width: 8),
                  Text('مواعيد تنبيه الصلاة'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'يمكنك اختيار أكثر من موعد تنبيه للصلاة الواحدة:',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ...standardOptions.map((entry) {
                        final isChecked = selected.contains(entry.key);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.value,
                            style: TextStyle(
                              fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                              color: isChecked ? AppColors.accentGold : null,
                            ),
                          ),
                          value: isChecked,
                          activeColor: AppColors.accentGold,
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
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accentGold),
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

  Widget _buildIqamahStepper(
    BuildContext context, {
    required String name,
    required int value,
    required ValueChanged<int> onChanged,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '$value دقيقة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 16),
                onPressed: value < 60 ? () => onChanged(value + 1) : null,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );

    if (!showDivider) return row;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تنبيهات الصلاة'),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. تنبيهات الصلاة (Notification & Adhan Sound)
              SettingsSectionCard(
                title: 'تنبيهات الصلاة والأذان',
                children: [
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 20, color: AppColors.accentGold),
                    ),
                    title: const Text('تفعيل إشعارات الصلاة', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('إظهار تنبيهات مواقيت الصلاة في شريط الإشعارات'),
                    value: state.notificationsEnabled,
                    activeThumbColor: AppColors.accentGold,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ToggleNotificationsEvent(val));
                    },
                  ),
                  if (state.notificationsEnabled) ...[
                    Divider(
                      height: 1,
                      indent: 66,
                      endIndent: 16,
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                    ),
                    SwitchListTile(
                      secondary: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.volume_up_outlined, size: 20, color: AppColors.accentGold),
                      ),
                      title: const Text('صوت الأذان والاهتزاز', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('تشغيل صوت أذان المؤذن كاملاً عند حلول مواعيد الصلاة والتنبيه'),
                      value: state.notificationSoundEnabled,
                      activeThumbColor: AppColors.accentGold,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleNotificationSoundEvent(val));
                      },
                    ),
                    if (state.notificationSoundEnabled) ...[
                      Divider(
                        height: 1,
                        indent: 66,
                        endIndent: 16,
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                      ),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.music_note_outlined, size: 20, color: AppColors.accentGold),
                        ),
                        title: const Text('صوت إشعار الأذان', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_getSoundDisplayName(state.notificationSoundType)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () => _showAdhanSoundDialog(context, state.notificationSoundType),
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 2. وقت التنبيه (Alert Offsets)
              if (state.notificationsEnabled) ...[
                SettingsSectionCard(
                  title: 'وقت التنبيه المسبق',
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.alarm_outlined, size: 20, color: AppColors.accentGold),
                      ),
                      title: const Text('مواعيد التنبيه قبل أو عند الأذان', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(_formatNotificationOffsets(state.notificationOffsets)),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => _showNotificationOffsetsDialog(context, state.notificationOffsets),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // 3. الإقامة (Iqamah Intervals)
              SettingsSectionCard(
                title: 'وقت الإقامة (الفارق بالدقائق بعد الأذان)',
                children: [
                  _buildIqamahStepper(
                    context,
                    name: 'الفجر',
                    value: state.iqamahFajr,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(fajr: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildIqamahStepper(
                    context,
                    name: 'الظهر',
                    value: state.iqamahDhuhr,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(dhuhr: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildIqamahStepper(
                    context,
                    name: 'العصر',
                    value: state.iqamahAsr,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(asr: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildIqamahStepper(
                    context,
                    name: 'المغرب',
                    value: state.iqamahMaghrib,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(maghrib: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildIqamahStepper(
                    context,
                    name: 'العشاء',
                    value: state.iqamahIsha,
                    showDivider: false,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(isha: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Educational Clarification Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                        const SizedBox(width: 8),
                        Text(
                          'توضيح الفروق في المنظومة:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• الإشعار: رسالة التنبيه التي تظهر في شريط إشعارات الهاتف.\n'
                      '• الأذان: صوت أذان المؤذن كاملاً عند حلول مواقيت الصلاة ومواعيد التنبيه.\n'
                      '• الإقامة: فارق الدقائق بين الأذان وبدء الصلاة في المسجد لمتابعة العد التنازلي بدقة.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
