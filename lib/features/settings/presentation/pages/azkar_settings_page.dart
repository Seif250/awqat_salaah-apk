import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../azkar/data/services/azkar_backup_service.dart';
import '../../../azkar/presentation/bloc/azkar_bloc.dart';
import '../../../azkar/presentation/bloc/azkar_event.dart';
import '../../../azkar/presentation/pages/azkar_page.dart';
import '../../../azkar/presentation/widgets/add_custom_zikr_dialog.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';

class AzkarSettingsPage extends StatefulWidget {
  const AzkarSettingsPage({super.key});

  @override
  State<AzkarSettingsPage> createState() => _AzkarSettingsPageState();
}

class _AzkarSettingsPageState extends State<AzkarSettingsPage> {
  void _showQiyamMinutesDialog(BuildContext context, int currentMinutes) {
    final p = context.palette;
    final options = [15, 30, 45, 60, 90];
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('وقت التنبيه لقيام الليل', style: AppTypography.sectionHeader(p.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((mins) {
            return RadioListTile<int>(
              title: Text('قبل أذان الفجر بـ $mins دقيقة', style: AppTypography.body(p.textPrimary)),
              value: mins,
              groupValue: currentMinutes,
              activeColor: p.primary,
              onChanged: (val) {
                if (val != null) {
                  context
                      .read<SettingsBloc>()
                      .add(UpdateAzkarQiyamMinutesEvent(val));
                  Navigator.pop(dialogCtx);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmRestoreDefaults(BuildContext context) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.restore_rounded, color: p.accent),
            const SizedBox(width: 8),
            Text('استعادة الأذكار الأصلية', style: AppTypography.sectionHeader(p.textPrimary)),
          ],
        ),
        content: Text(
          'هل تريد استعادة جميع أذكار السنة النبوية الافتراضية؟\n\n'
          'سيتم استرجاع جميع الأذكار الأصلية مع الاحتفاظ بأذكارك المخصصة التي أضفتها بنفسك.',
          style: AppTypography.body(p.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('إلغاء', style: AppTypography.meta(p.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.primary, foregroundColor: p.onPrimary),
            onPressed: () {
              context.read<AzkarBloc>().add(const RestoreDefaultAzkarEvent());
              Navigator.pop(dialogCtx);
              AppSnackBar.showSuccess(context, 'تمت استعادة الأذكار الافتراضية بنجاح');
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: Text('الأذكار والورد', style: AppTypography.pageTitle(p.textPrimary)),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. تنبيهات الأذكار
              SettingsSectionCard(
                title: 'تنبيهات أوقات الأذكار',
                children: [
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.wb_sunny_outlined, size: 20, color: p.accentText),
                    ),
                    title: Text('أذكار الصباح', style: AppTypography.rowTitle(p.textPrimary)),
                    subtitle: Text('تنبيه صباحي بعد شروق الشمس', style: AppTypography.meta(p.textSecondary)),
                    value: state.isAzkarMorningReminderEnabled,
                    activeThumbColor: p.primary,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(ToggleAzkarMorningReminderEvent(val));
                    },
                  ),
                  Divider(height: 1, indent: 66, endIndent: 16, color: p.hairline),
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.nightlight_outlined, size: 20, color: p.accentText),
                    ),
                    title: Text('أذكار المساء', style: AppTypography.rowTitle(p.textPrimary)),
                    subtitle: Text('تنبيه مسائي بعد صلاة العصر والمغرب', style: AppTypography.meta(p.textSecondary)),
                    value: state.isAzkarEveningReminderEnabled,
                    activeThumbColor: p.primary,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(ToggleAzkarEveningReminderEvent(val));
                    },
                  ),
                  Divider(height: 1, indent: 66, endIndent: 16, color: p.hairline),
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bedtime_outlined, size: 20, color: p.accentText),
                    ),
                    title: Text('أذكار النوم', style: AppTypography.rowTitle(p.textPrimary)),
                    subtitle: Text('تذكير ليلي قبل النوم', style: AppTypography.meta(p.textSecondary)),
                    value: state.isAzkarSleepReminderEnabled,
                    activeThumbColor: p.primary,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(ToggleAzkarSleepReminderEvent(val));
                    },
                  ),
                  Divider(height: 1, indent: 66, endIndent: 16, color: p.hairline),
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.dark_mode_outlined, size: 20, color: p.accentText),
                    ),
                    title: Text('قيام الليل والأسحار', style: AppTypography.rowTitle(p.textPrimary)),
                    subtitle: Text(
                      'تنبيه قبل الفجر بـ ${state.azkarQiyamMinutesBeforeFajr} دقيقة',
                      style: AppTypography.meta(p.textSecondary),
                    ),
                    value: state.isAzkarQiyamReminderEnabled,
                    activeThumbColor: p.primary,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(ToggleAzkarQiyamReminderEvent(val));
                    },
                  ),
                  if (state.isAzkarQiyamReminderEnabled) ...[
                    Divider(height: 1, indent: 66, endIndent: 16, color: p.hairline),
                    SettingsTile(
                      icon: Icons.access_time_rounded,
                      title: 'وقت الاستيقاظ لقيام الليل',
                      subtitle:
                          'قبل أذان الفجر بـ ${state.azkarQiyamMinutesBeforeFajr} دقيقة',
                      showDivider: false,
                      onTap: () => _showQiyamMinutesDialog(
                          context, state.azkarQiyamMinutesBeforeFajr),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 2. الورد اليومي وإدارة الأذكار
              SettingsSectionCard(
                title: 'إدارة الأذكار',
                children: [
                  SettingsTile(
                    icon: Icons.auto_stories_outlined,
                    title: 'فتح صفحة الأذكار والورد',
                    subtitle: 'استعراض الأذكار ومتابعة الورد اليومي',
                    showDivider: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(page: const AzkarPage()),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'إضافة ذكر جديد',
                    subtitle: 'أضف ذكراً مخصصاً وحدد عدد تكراره وتوقيت تنبيهه',
                    showDivider: true,
                    onTap: () {
                      AddCustomZikrDialog.show(
                        context,
                        onAdd: (zikr) {
                          context
                              .read<AzkarBloc>()
                              .add(AddCustomZikrEvent(zikr));
                          AppSnackBar.showSuccess(context, 'تمت إضافة الذكر بنجاح');
                        },
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.restore_rounded,
                    title: 'استعادة الأذكار الافتراضية',
                    subtitle:
                        'استرجاع أذكار السنة النبوية دون المساس بأذكارك المضافة',
                    showDivider: false,
                    onTap: () => _confirmRestoreDefaults(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. النسخ الاحتياطي لأذكاري
              SettingsSectionCard(
                title: 'النسخ الاحتياطي لأذكاري',
                children: [
                  SettingsTile(
                    icon: Icons.save_alt_rounded,
                    title: 'حفظ نسخة احتياطية الآن',
                    subtitle: 'تصدير أذكارك المخصصة لحمايتها أو نقلها لجهاز آخر',
                    showDivider: true,
                    onTap: () => AzkarBackupService.performBackupFlow(context),
                  ),
                  SettingsTile(
                    icon: Icons.file_open_rounded,
                    title: 'استرجاع نسخة محفوظة',
                    subtitle: 'استيراد ملف الأذكار المخصصة المحفوظ مسبقاً',
                    showDivider: false,
                    onTap: () => AzkarBackupService.performRestoreFlow(context),
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

