import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/widget_service.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../../../azkar/presentation/pages/azkar_page.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              _buildSectionHeader(context, 'إشعارات وتنبيهات الصلاة', Icons.notifications_active_outlined),
              _buildCard(
                context,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('تفعيل إشعارات الصلاة'),
                      subtitle: const Text('إرسال تنبيه على الشاشة عند دخول الوقت'),
                      value: state.notificationsEnabled,
                      onChanged: (val) async {
                        if (val) {
                          final ns = NotificationService();
                          final granted = await ns.requestNotificationsPermission();
                          if (!granted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ يرجى السماح بالإشعارات من إعدادات النظام ليعمل التنبيه'),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                        if (context.mounted) {
                          context.read<SettingsBloc>().add(ToggleNotificationsEvent(val));
                        }
                      },
                    ),
                    if (state.notificationsEnabled) ...[
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('صوت التنبيه والاهتزاز'),
                        subtitle: const Text('تشغيل صوت إشعار النظام الافتراضي'),
                        value: state.notificationSoundEnabled,
                        onChanged: (val) {
                          context.read<SettingsBloc>().add(ToggleNotificationSoundEvent(val));
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('وقت التنبيه'),
                        subtitle: Text(
                          _formatNotificationOffsets(state.notificationOffsets),
                          style: const TextStyle(height: 1.3),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () => _showNotificationOffsetsDialog(
                          context,
                          state.notificationOffsets,
                        ),
                      ),
                      const Divider(height: 1),
                      // ── TEST 1: Simplest possible notification (default sound) ──
                      ListTile(
                        leading: const Icon(Icons.notifications_active, color: Colors.blue),
                        title: const Text('تجربة 1: إشعار بسيط (صوت النظام)'),
                        subtitle: const Text('أبسط إشعار ممكن بالصوت الافتراضي للتأكد أن الإشعارات تعمل أصلاً'),
                        onTap: () async {
                          final result = await NotificationService().showSimpleTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result == 'success'
                                    ? '✅ تم إرسال الإشعار البسيط! تفقد شريط الإشعارات'
                                    : '❌ فشل: $result'),
                                duration: const Duration(seconds: 5),
                                backgroundColor: result == 'success' ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      // ── TEST 2: Takbeer sound notification ──
                      ListTile(
                        leading: const Icon(Icons.volume_up_rounded, color: AppColors.accentGold),
                        title: const Text('تجربة 2: إشعار بصوت التكبير'),
                        subtitle: const Text('إشعار فوري مع صوت التكبير المخصص'),
                        onTap: () async {
                          final result = await NotificationService().showTakbeerTestNotification();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result == 'success'
                                    ? '✅ تم إرسال إشعار التكبير! تفقد شريط الإشعارات'
                                    : '❌ فشل: $result'),
                                duration: const Duration(seconds: 5),
                                backgroundColor: result == 'success' ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      // ── TEST 3: Scheduled alarm (background) ──
                      ListTile(
                        leading: const Icon(Icons.alarm_on_rounded, color: Colors.deepPurple),
                        title: const Text('تجربة 3: تنبيه مجدول (بعد 15 ثانية)'),
                        subtitle: const Text('أغلق التطبيق تماماً واقفل الشاشة — سيصدح التكبير بعد 15 ثانية'),
                        onTap: () async {
                          final result = await NotificationService().scheduleTestAlarmInSeconds(
                            seconds: 15,
                            isSoundEnabled: state.notificationSoundEnabled,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.startsWith('failed')
                                    ? '❌ فشل الجدولة: $result'
                                    : '✅ تمت الجدولة بنجاح ($result)! أغلق التطبيق واقفل الشاشة'),
                                duration: const Duration(seconds: 6),
                                backgroundColor: result.startsWith('failed') ? Colors.red : Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      // ── Battery Optimization Exemption ──
                      ListTile(
                        leading: const Icon(Icons.battery_saver_rounded, color: Colors.green),
                        title: const Text('إيقاف تقييد البطارية'),
                        subtitle: const Text('ضروري لضمان عمل الأذان والإشعارات في الخلفية — اضغط لإعفاء التطبيق من وضع توفير الطاقة'),
                        onTap: () async {
                          final ns = NotificationService();
                          final granted = await ns.requestBatteryOptimizationExemption();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(granted
                                    ? '✅ التطبيق معفى من تقييد البطارية — الأذان سيعمل في الخلفية بإذن الله'
                                    : '⚠️ يرجى إعفاء التطبيق يدوياً من إعدادات البطارية'),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1),
                      // ── AutoStart Guidance for Realme/Oppo/Xiaomi ──
                      ListTile(
                        leading: const Icon(Icons.rocket_launch_rounded, color: Colors.orange),
                        title: const Text('تفعيل التشغيل التلقائي (AutoStart)'),
                        subtitle: const Text('مهم لهواتف Realme/Oppo/Xiaomi — افتح الإعدادات وفعّل التشغيل التلقائي للتطبيق'),
                        onTap: () => _showAutoStartGuide(context),
                      ),
                      const Divider(height: 1),
                      // ── Diagnostic Check ──
                      ListTile(
                        leading: const Icon(Icons.bug_report_rounded, color: Colors.blueGrey),
                        title: const Text('فحص حالة الإشعارات'),
                        subtitle: const Text('عرض عدد التنبيهات المجدولة فعلياً وسجل التشخيص'),
                        onTap: () => _showDiagnosticsDialog(context),
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

              // Section: Azkar & Qiyam Reminders
              _buildSectionHeader(context, 'تنبيهات الأذكار وقيام الليل', Icons.auto_stories_outlined),
              _buildCard(
                context,
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('أذكار الصباح'),
                      subtitle: const Text('تنبيه بعد الفجر + تذكير إضافي قبل الظهر إذا لم تقرأ'),
                      value: state.isAzkarMorningReminderEnabled,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleAzkarMorningReminderEvent(val));
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('أذكار المساء'),
                      subtitle: const Text('تنبيه وقت العصر + تذكير قبل العشاء إذا لم تقرأ'),
                      value: state.isAzkarEveningReminderEnabled,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleAzkarEveningReminderEvent(val));
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('أذكار النوم'),
                      subtitle: const Text('تنبيه لطيف قبل النوم في الساعة 10:30 مساءً'),
                      value: state.isAzkarSleepReminderEnabled,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleAzkarSleepReminderEvent(val));
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('قيام الليل والأسحار'),
                      subtitle: Text(
                        state.isAzkarQiyamReminderEnabled
                            ? 'تنبيه لطيف قبل أذان الفجر بـ ${state.azkarQiyamMinutesBeforeFajr} دقيقة'
                            : 'تنبيه للاستغفار بالأسحار وقيام الليل',
                      ),
                      value: state.isAzkarQiyamReminderEnabled,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleAzkarQiyamReminderEvent(val));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.auto_stories_rounded, color: AppColors.accentGold),
                      title: const Text('فتح صفحة الأذكار والورد اليومي', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('تصفح وقراءة أذكار الصباح، المساء، والنوم وقيام الليل'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AzkarPage()),
                        );
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
              const SizedBox(height: 24),

              // Section: Widget Diagnostics
              _buildSectionHeader(context, 'تشخيص الـ Widget', Icons.bug_report_outlined),
              _buildCard(
                context,
                child: ListTile(
                  title: const Text('عرض سجل تشخيص الـ Widget'),
                  subtitle: const Text('لمعرفة حالة التحديث التلقائي والأخطاء'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _showWidgetDiagnosticsDialog(context),
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
      const MapEntry(5, 'بعد الأذان بـ 5 دقائق (فترة الإقامة)'),
      const MapEntry(10, 'بعد الأذان بـ 10 دقائق (فترة الإقامة)'),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final standardKeys = standardOptions.map((e) => e.key).toSet();
            final customKeys = selected.where((e) => !standardKeys.contains(e)).toList()..sort();

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
                      if (customKeys.isNotEmpty) ...[
                        const Divider(height: 16),
                        const Text(
                          'المواعيد المخصصة:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        ...customKeys.map((cKey) {
                          final label = cKey < 0
                              ? 'قبل الأذان بـ ${-cKey} دقيقة'
                              : 'بعد الأذان بـ $cKey دقيقة';
                          final isChecked = selected.contains(cKey);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              label,
                              style: TextStyle(
                                fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                                color: isChecked ? AppColors.accentGold : null,
                              ),
                            ),
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  selected.remove(cKey);
                                  if (selected.isEmpty) selected.add(0);
                                });
                              },
                            ),
                            value: isChecked,
                            activeColor: AppColors.accentGold,
                            onChanged: (bool? val) {
                              setDialogState(() {
                                if (val == true) {
                                  selected.add(cKey);
                                } else {
                                  if (selected.length > 1) {
                                    selected.remove(cKey);
                                  }
                                }
                              });
                            },
                          );
                        }),
                      ],
                      const Divider(height: 16),
                      Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.accentGold),
                          label: const Text(
                            'إضافة وقت تنبيه مخصص',
                            style: TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final customOffset = await _showCustomOffsetInputDialog(context);
                            if (customOffset != null) {
                              setDialogState(() {
                                selected.add(customOffset);
                              });
                            }
                          },
                        ),
                      ),
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                  ),
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

  Future<int?> _showCustomOffsetInputDialog(BuildContext context) async {
    int minutes = 5;
    bool isBefore = true;
    final controller = TextEditingController(text: '5');

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setInputState) {
            return AlertDialog(
              title: const Text('إضافة وقت مخصص'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('قبل الأذان')),
                          selected: isBefore,
                          selectedColor: AppColors.accentGold.withValues(alpha: 0.2),
                          onSelected: (val) {
                            if (val) setInputState(() => isBefore = true);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('بعد الأذان')),
                          selected: !isBefore,
                          selectedColor: AppColors.accentGold.withValues(alpha: 0.2),
                          onSelected: (val) {
                            if (val) setInputState(() => isBefore = false);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'عدد الدقائق',
                      suffixText: 'دقيقة',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        minutes = parsed;
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                  ),
                  onPressed: () {
                    final finalMinutes = int.tryParse(controller.text) ?? minutes;
                    if (finalMinutes <= 0) {
                      Navigator.pop(ctx, 0);
                    } else {
                      final signedOffset = isBefore ? -finalMinutes : finalMinutes;
                      Navigator.pop(ctx, signedOffset);
                    }
                  },
                  child: const Text('إضافة'),
                ),
              ],
            );
          },
        );
      },
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

  void _showAutoStartGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('تفعيل التشغيل التلقائي', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هواتف Realme / Oppo / Xiaomi تمنع التطبيقات من العمل في الخلفية تلقائياً.\n\n'
                'لتفعيل الأذان والإشعارات بشكل دائم، اتبع الخطوات التالية:',
                style: TextStyle(height: 1.6),
              ),
              SizedBox(height: 16),
              Text('📱 لهواتف Realme / Oppo:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                '1. افتح الإعدادات → إدارة التطبيقات\n'
                '2. ابحث عن "أوقات الصلاة"\n'
                '3. فعّل "السماح بالتشغيل التلقائي" (Auto-launch)\n'
                '4. في "استخدام البطارية" اختر "السماح بالعمل في الخلفية"\n'
                '5. في التطبيقات الأخيرة (Recent Apps) اضغط مطولاً على التطبيق ثم اقفله 🔒',
                style: TextStyle(height: 1.8),
              ),
              SizedBox(height: 16),
              Text('📱 لهواتف Xiaomi:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                '1. افتح الإعدادات → التطبيقات → إدارة التطبيقات\n'
                '2. ابحث عن "أوقات الصلاة"\n'
                '3. فعّل "التشغيل التلقائي" (AutoStart)\n'
                '4. في "توفير البطارية" اختر "بلا قيود"',
                style: TextStyle(height: 1.8),
              ),
              SizedBox(height: 16),
              Text('📱 لهواتف Samsung:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                '1. افتح الإعدادات → العناية بالجهاز → البطارية\n'
                '2. اختر "تطبيقات لا تراقبها" وأضف "أوقات الصلاة"\n'
                '3. أو اختر "التطبيقات غير النائمة"',
                style: TextStyle(height: 1.8),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await openAppSettings();
            },
            child: const Text('فتح إعدادات التطبيق'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  void _showDiagnosticsDialog(BuildContext context) async {
    final ns = NotificationService();
    final pending = await ns.getPendingNotifications();
    final batteryExempt = await ns.isBatteryOptimizationExempted();
    final notifsEnabled = await ns.areNotificationsEnabled();
    final exactAllowed = await ns.canScheduleExactAlarms();
    final log = ns.diagnosticLog;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report_rounded, color: Colors.blueGrey),
            SizedBox(width: 8),
            Expanded(child: Text('تشخيص الإشعارات', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pending.isNotEmpty ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            pending.isNotEmpty ? Icons.check_circle : Icons.error,
                            color: pending.isNotEmpty ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'التنبيهات المجدولة: ${pending.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            notifsEnabled ? Icons.check_circle : Icons.error,
                            color: notifsEnabled ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notifsEnabled
                                  ? 'إذن الإشعارات: مفعّل للنظام ✅'
                                  : 'إذن الإشعارات: معطل بالنظام ❌',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: notifsEnabled ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            exactAllowed ? Icons.check_circle : Icons.warning,
                            color: exactAllowed ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exactAllowed
                                  ? 'المنبهات الدقيقة: مسموحة ✅'
                                  : 'المنبهات الدقيقة: مقيدة بالنظام ⚠️',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: exactAllowed ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            batteryExempt ? Icons.check_circle : Icons.info_outline,
                            color: batteryExempt ? Colors.green : Colors.blueGrey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              batteryExempt
                                  ? 'إعفاء البطارية: معفى ✅'
                                  : 'إعفاء البطارية: عادي (اختياري)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: batteryExempt ? Colors.green : Colors.blueGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('أقرب 5 تنبيهات مجدولة:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...pending.take(5).map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• [${p.id}] ${p.title ?? "—"}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ],
                if (log.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('سجل التشخيص (آخر 20 سطر):', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      log.reversed.take(20).join('\n'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Colors.greenAccent,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showWidgetDiagnosticsDialog(BuildContext context) async {
    // Show loading indicator while fetching diagnostics
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final diagnostics = await WidgetService.getWidgetDiagnostics();

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss loading

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E23),
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: AppColors.accentGold, size: 22),
            const SizedBox(width: 8),
            Text(
              'تشخيص الـ Widget',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Force refresh button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await WidgetService.forceRefreshWidget();
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث الـ Widget بنجاح ✅'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('تحديث الـ Widget الآن'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentGold,
                    side: const BorderSide(color: AppColors.accentGold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              // Diagnostic log
              Expanded(
                child: SingleChildScrollView(
                  reverse: true, // scroll to bottom (latest entries)
                  child: SelectableText(
                    diagnostics,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.greenAccent,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
