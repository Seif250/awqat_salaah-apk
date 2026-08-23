import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          // Trigger prayer times recalculation whenever settings change
          context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Section: Location
              _buildSectionHeader(context, 'الموقع الجغرافي', Icons.location_on_outlined),
              _buildCard(
                context,
                child: ListTile(
                  title: const Text('تغيير المدينة أو الموقع'),
                  subtitle: const Text('استخدام GPS أو اختيار من قائمة المدن'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    await LocationPickerSheet.show(context);
                    if (context.mounted) {
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Section: Calculation
              _buildSectionHeader(context, 'حساب المواقيت', Icons.calculate_outlined),
              _buildCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('طريقة الحساب'),
                      subtitle: Text(state.calculationMethod.displayNameArabic),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => _showCalculationMethodDialog(context, state.calculationMethod),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('المذهب الفقهي (صلاة العصر)'),
                      subtitle: Text(state.madhab == AppMadhab.shafi
                          ? 'الشافعي / المالكي / الحنبلي (المثل)'
                          : 'الحنفي (المثلين)'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => _showMadhabDialog(context, state.madhab),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Iqamah Intervals
              _buildSectionHeader(context, 'فارق وقت الإقامة (بعد الأذان بالدقائق)', Icons.timer_outlined),
              _buildCard(
                context,
                child: Column(
                  children: [
                    _buildIqamahRow(context, 'الفجر', state.iqamahFajr, (val) {
                      if (val >= 0) context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(fajr: val));
                    }),
                    _buildIqamahRow(context, 'الظهر', state.iqamahDhuhr, (val) {
                      if (val >= 0) context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(dhuhr: val));
                    }),
                    _buildIqamahRow(context, 'العصر', state.iqamahAsr, (val) {
                      if (val >= 0) context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(asr: val));
                    }),
                    _buildIqamahRow(context, 'المغرب', state.iqamahMaghrib, (val) {
                      if (val >= 0) context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(maghrib: val));
                    }),
                    _buildIqamahRow(context, 'العشاء', state.iqamahIsha, (val) {
                      if (val >= 0) context.read<SettingsBloc>().add(UpdateIqamahOffsetsEvent(isha: val));
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Notifications
              _buildSectionHeader(context, 'الإشعارات (صامتة)', Icons.notifications_none_rounded),
              _buildCard(
                context,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('تفعيل إشعارات الصلاة'),
                      subtitle: const Text('إشعارات هادئة بدون صوت أو اهتزاز'),
                      value: state.notificationsEnabled,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleNotificationsEvent(val));
                      },
                    ),
                    if (state.notificationsEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('وقت التنبيه'),
                        subtitle: Text(state.notificationOffsetMinutes == 0
                            ? 'عند دخول وقت الصلاة'
                            : 'قبل الصلاة بـ ${state.notificationOffsetMinutes} دقائق'),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () => _showNotificationOffsetDialog(
                          context,
                          state.notificationOffsetMinutes,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Appearance & Time
              _buildSectionHeader(context, 'المظهر والوقت', Icons.palette_outlined),
              _buildCard(
                context,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('المظهر (Theme)'),
                      subtitle: Text(_getThemeName(state.themeMode)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () => _showThemeDialog(context, state.themeMode),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('تنسيق 24 ساعة'),
                      subtitle: const Text('عرض الوقت بتنسيق 24:00 بدلاً من 12:00 م/ص'),
                      value: state.is24HourFormat,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(Toggle24HourFormatEvent(val));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section: Prayer Adjustments
              _buildSectionHeader(context, 'تعديل يدوي بالدقائق (Adjustments)', Icons.tune_rounded),
              _buildCard(
                context,
                child: Column(
                  children: [
                    _buildAdjustmentRow(context, 'الفجر', state.adjustFajr, (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(fajr: val));
                    }),
                    _buildAdjustmentRow(context, 'الشروق', state.adjustSunrise, (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(sunrise: val));
                    }),
                    _buildAdjustmentRow(context, 'الظهر', state.adjustDhuhr, (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(dhuhr: val));
                    }),
                    _buildAdjustmentRow(context, 'العصر', state.adjustAsr, (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(asr: val));
                    }),
                    _buildAdjustmentRow(context, 'المغرب', state.adjustMaghrib, (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(maghrib: val));
                    }),
                    _buildAdjustmentRow(context, 'العشاء', state.adjustIsha, (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(isha: val));
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accentGold),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      ),
    );
  }

  Widget _buildIqamahRow(
    BuildContext context,
    String name,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(
                'بعد الأذان',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () => onChanged(value - 1),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '$value دقيقة',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => onChanged(value + 1),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentRow(
    BuildContext context,
    String name,
    int value,
    ValueChanged<int> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: () => onChanged(value - 1),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${value >= 0 ? '+' : ''}$value د',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => onChanged(value + 1),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'فاتح (Light)';
      case ThemeMode.dark:
        return 'داكن (Dark)';
      case ThemeMode.system:
        return 'تلقائي (حسب النظام)';
    }
  }

  void _showCalculationMethodDialog(BuildContext context, AppCalculationMethod current) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('طريقة الحساب'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: AppCalculationMethod.values.map((method) {
              return RadioListTile<AppCalculationMethod>(
                title: Text(method.displayNameArabic),
                value: method,
                groupValue: current,
                onChanged: (val) {
                  if (val != null) {
                    context.read<SettingsBloc>().add(ChangeCalculationMethodEvent(val));
                    Navigator.pop(dialogCtx);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showMadhabDialog(BuildContext context, AppMadhab current) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('المذهب الفقهي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppMadhab>(
              title: const Text('الشافعي / المالكي / الحنبلي'),
              subtitle: const Text('ظل الشيء مثله (الجمهور)'),
              value: AppMadhab.shafi,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeMadhabEvent(val));
                  Navigator.pop(dialogCtx);
                }
              },
            ),
            RadioListTile<AppMadhab>(
              title: const Text('الحنفي'),
              subtitle: const Text('ظل الشيء مثليه'),
              value: AppMadhab.hanafi,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeMadhabEvent(val));
                  Navigator.pop(dialogCtx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationOffsetDialog(BuildContext context, int current) {
    final options = [
      const MapEntry(0, 'عند دخول وقت الصلاة'),
      const MapEntry(5, 'قبل الصلاة بـ 5 دقائق'),
      const MapEntry(10, 'قبل الصلاة بـ 10 دقائق'),
      const MapEntry(15, 'قبل الصلاة بـ 15 دقيقة'),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('موعد الإشعار'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((entry) {
            return RadioListTile<int>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeNotificationOffsetEvent(val));
                  Navigator.pop(dialogCtx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, ThemeMode current) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('المظهر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('تلقائي (حسب النظام)'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeThemeModeEvent(val));
                  Navigator.pop(dialogCtx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('فاتح (Light)'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeThemeModeEvent(val));
                  Navigator.pop(dialogCtx);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('داكن (Dark)'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeThemeModeEvent(val));
                  Navigator.pop(dialogCtx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
