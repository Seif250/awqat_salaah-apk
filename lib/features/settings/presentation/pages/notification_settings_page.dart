import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/adhan_sound_dialog.dart';
import '../widgets/notification_offsets_dialog.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';
import 'battery_settings_page.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

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
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
              SizedBox(
                width: 70,
                child: Text(
                  '$value دقيقة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 16),
                onPressed: value < 60 ? () => onChanged(value + 1) : null,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text('تنبيهات الصلاة',
            style: AppTypography.pageTitle(p.textPrimary)),
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
                        color: p.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.notifications_outlined,
                          size: 20, color: p.accentText),
                    ),
                    title: Text('تفعيل إشعارات الصلاة',
                        style: AppTypography.rowTitle(p.textPrimary)),
                    subtitle: Text(
                        'إظهار تنبيهات مواقيت الصلاة في شريط الإشعارات',
                        style: AppTypography.meta(p.textSecondary)),
                    value: state.notificationsEnabled,
                    activeThumbColor: p.primary,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(ToggleNotificationsEvent(val));
                    },
                  ),
                  if (state.notificationsEnabled) ...[
                    Divider(
                        height: 1,
                        indent: 66,
                        endIndent: 16,
                        color: p.hairline),
                    SwitchListTile(
                      secondary: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: p.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.volume_up_outlined,
                            size: 20, color: p.accentText),
                      ),
                      title: Text('صوت الأذان والاهتزاز',
                          style: AppTypography.rowTitle(p.textPrimary)),
                      subtitle: Text(
                          'تشغيل صوت أذان المؤذن كاملاً عند حلول مواعيد الصلاة والتنبيه',
                          style: AppTypography.meta(p.textSecondary)),
                      value: state.notificationSoundEnabled,
                      activeThumbColor: p.primary,
                      onChanged: (val) {
                        context
                            .read<SettingsBloc>()
                            .add(ToggleNotificationSoundEvent(val));
                      },
                    ),
                    if (state.notificationSoundEnabled) ...[
                      Divider(
                          height: 1,
                          indent: 66,
                          endIndent: 16,
                          color: p.hairline),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.music_note_outlined,
                              size: 20, color: p.accentText),
                        ),
                        title: Text('نغمة الأذان',
                            style: AppTypography.rowTitle(p.textPrimary)),
                        subtitle: Text(
                            AdhanSoundDialog.getSoundDisplayName(
                                state.notificationSoundType),
                            style: AppTypography.meta(p.textSecondary)),
                        trailing: Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: p.textSecondary),
                        onTap: () => AdhanSoundDialog.show(
                            context, state.notificationSoundType),
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 2. التنبيه قبل الأذان
              if (state.notificationsEnabled) ...[
                SettingsSectionCard(
                  title: 'التنبيه قبل الأذان',
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: p.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.alarm_outlined,
                            size: 20, color: p.accentText),
                      ),
                      title: Text('موعد التذكير بالأذان',
                          style: AppTypography.rowTitle(p.textPrimary)),
                      subtitle: Text(
                          NotificationOffsetsDialog.formatNotificationOffsets(
                              state.notificationOffsets),
                          style: AppTypography.meta(p.textSecondary)),
                      trailing: Icon(Icons.chevron_left_rounded,
                          color: p.textSecondary),
                      onTap: () => NotificationOffsetsDialog.show(
                          context, state.notificationOffsets),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // 3. الإقامة
              SettingsSectionCard(
                title: 'مدة الانتظار للإقامة (بالدقائق بعد الأذان)',
                children: [
                  _buildIqamahStepper(
                    context,
                    name: 'الفجر',
                    value: state.iqamahFajr,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateIqamahOffsetsEvent(fajr: val));
                      context
                          .read<PrayerBloc>()
                          .add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildIqamahStepper(
                    context,
                    name: 'الظهر',
                    value: state.iqamahDhuhr,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateIqamahOffsetsEvent(dhuhr: val));
                      context
                          .read<PrayerBloc>()
                          .add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildIqamahStepper(
                    context,
                    name: 'العصر',
                    value: state.iqamahAsr,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateIqamahOffsetsEvent(asr: val));
                      context
                          .read<PrayerBloc>()
                          .add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildIqamahStepper(
                    context,
                    name: 'المغرب',
                    value: state.iqamahMaghrib,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateIqamahOffsetsEvent(maghrib: val));
                      context
                          .read<PrayerBloc>()
                          .add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildIqamahStepper(
                    context,
                    name: 'العشاء',
                    value: state.iqamahIsha,
                    showDivider: false,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateIqamahOffsetsEvent(isha: val));
                      context
                          .read<PrayerBloc>()
                          .add(const RefreshPrayerTimesEvent());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. استقرار التنبيهات في الخلفية
              SettingsSectionCard(
                title: 'العمل في الخلفية واستقرار الأذان',
                children: [
                  SettingsTile(
                    icon: Icons.battery_saver_outlined,
                    title: 'استثناء البطارية والتشغيل التلقائي',
                    subtitle: 'لضمان انطلاق الأذان في وقته عند إغلاق الشاشة',
                    showDivider: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(page: const BatterySettingsPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
