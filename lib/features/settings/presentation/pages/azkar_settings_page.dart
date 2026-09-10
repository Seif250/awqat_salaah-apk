import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../azkar/presentation/bloc/azkar_bloc.dart';
import '../../../azkar/presentation/bloc/azkar_event.dart';
import '../../../azkar/presentation/pages/azkar_page.dart';
import '../../../azkar/presentation/widgets/add_custom_zikr_dialog.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';

class AzkarSettingsPage extends StatelessWidget {
  const AzkarSettingsPage({super.key});

  void _showQiyamMinutesDialog(BuildContext context, int currentMinutes) {
    final options = [15, 30, 45, 60, 90];
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('وقت التنبيه لقيام الليل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((mins) {
            return RadioListTile<int>(
              title: Text('قبل أذان الفجر بـ $mins دقيقة'),
              value: mins,
              groupValue: currentMinutes,
              activeColor: AppColors.accentGold,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(UpdateAzkarQiyamMinutesEvent(val));
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
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text('استعادة الأذكار الأصلية'),
          ],
        ),
        content: const Text(
          'هل تريد استعادة جميع أذكار السنة النبوية الافتراضية؟\n\n'
          'سيتم استرجاع جميع الأذكار الأصلية مع الاحتفاظ بأذكارك المخصصة التي أضفتها بنفسك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentGold),
            onPressed: () {
              context.read<AzkarBloc>().add(const RestoreDefaultAzkarEvent());
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت استعادة الأذكار الافتراضية بنجاح')),
              );
            },
            child: const Text('استعادة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأذكار والورد'),
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
                        color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.wb_sunny_outlined, size: 20, color: AppColors.accentGold),
                    ),
                    title: const Text('أذكار الصباح', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('تنبيه صباحي بعد شروق الشمس'),
                    value: state.isAzkarMorningReminderEnabled,
                    activeColor: AppColors.accentGold,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ToggleAzkarMorningReminderEvent(val));
                    },
                  ),
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
                      child: const Icon(Icons.nightlight_outlined, size: 20, color: AppColors.accentGold),
                    ),
                    title: const Text('أذكار المساء', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('تنبيه مسائي بعد صلاة العصر والمغرب'),
                    value: state.isAzkarEveningReminderEnabled,
                    activeColor: AppColors.accentGold,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ToggleAzkarEveningReminderEvent(val));
                    },
                  ),
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
                      child: const Icon(Icons.bedtime_outlined, size: 20, color: AppColors.accentGold),
                    ),
                    title: const Text('أذكار النوم', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('تذكير ليلي قبل النوم'),
                    value: state.isAzkarSleepReminderEnabled,
                    activeColor: AppColors.accentGold,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ToggleAzkarSleepReminderEvent(val));
                    },
                  ),
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
                      child: const Icon(Icons.dark_mode_outlined, size: 20, color: AppColors.accentGold),
                    ),
                    title: const Text('قيام الليل والأسحار', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('تنبيه قبل الفجر بـ ${state.azkarQiyamMinutesBeforeFajr} دقيقة'),
                    value: state.isAzkarQiyamReminderEnabled,
                    activeColor: AppColors.accentGold,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ToggleAzkarQiyamReminderEvent(val));
                    },
                  ),
                  if (state.isAzkarQiyamReminderEnabled) ...[
                    Divider(
                      height: 1,
                      indent: 66,
                      endIndent: 16,
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                    ),
                    SettingsTile(
                      icon: Icons.access_time_rounded,
                      title: 'وقت الاستيقاظ لقيام الليل',
                      subtitle: 'قبل أذان الفجر بـ ${state.azkarQiyamMinutesBeforeFajr} دقيقة',
                      showDivider: false,
                      onTap: () => _showQiyamMinutesDialog(context, state.azkarQiyamMinutesBeforeFajr),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 2. الورد اليومي وإدارة الأذكار
              SettingsSectionCard(
                title: 'الورد اليومي وإدارة الأذكار',
                children: [
                  SettingsTile(
                    icon: Icons.auto_stories_outlined,
                    title: 'فتح صفحة الأذكار والورد',
                    subtitle: 'استعراض الأذكار، متابعة الورد، والتسبيح الإلكتروني',
                    showDivider: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AzkarPage()),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'إضافة ذكر مخصص',
                    subtitle: 'أضف أذكارك الخاصة وحدد عدد التكرار والتنبيه',
                    showDivider: true,
                    onTap: () {
                      AddCustomZikrDialog.show(
                        context,
                        onAdd: (zikr) {
                          context.read<AzkarBloc>().add(AddCustomZikrEvent(zikr));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تمت إضافة الذكر بنجاح')),
                          );
                        },
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.restore_rounded,
                    title: 'استعادة الأذكار الافتراضية',
                    subtitle: 'استرجاع أذكار السنة النبوية إذا قمت بحذف أي منها',
                    showDivider: false,
                    onTap: () => _confirmRestoreDefaults(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. سلوك الإنجاز
              SettingsSectionCard(
                title: 'سلوك إنجاز الورد',
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.accentGold),
                    ),
                    title: const Text('إعادة ضبط الورد اليومي', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text(
                      'يتم تصفير عداد إنجاز اليوم تلقائياً مع مطلع كل يوم جديد مع الحفاظ على إجمالي التسبيحات مدى الحياة.',
                    ),
                    trailing: const Icon(Icons.check_circle_outline_rounded, color: Colors.green),
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
