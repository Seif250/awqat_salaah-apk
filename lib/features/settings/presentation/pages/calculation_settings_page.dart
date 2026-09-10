import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';

class CalculationSettingsPage extends StatelessWidget {
  const CalculationSettingsPage({super.key});

  void _showCalculationMethodDialog(BuildContext context, AppCalculationMethod current) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('طريقة حساب المواقيت'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: AppCalculationMethod.values.map((method) {
              return RadioListTile<AppCalculationMethod>(
                title: Text(method.displayNameArabic, style: const TextStyle(fontWeight: FontWeight.w600)),
                value: method,
                groupValue: current,
                activeColor: AppColors.accentGold,
                onChanged: (val) {
                  if (val != null) {
                    context.read<SettingsBloc>().add(ChangeCalculationMethodEvent(val));
                    context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
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
        title: const Text('المذهب الفقهي (صلاة العصر)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppMadhab>(
              title: const Text('الشافعي / المالكي / الحنبلي'),
              subtitle: const Text('ظل الشيء مثله (الجمهور)'),
              value: AppMadhab.shafi,
              groupValue: current,
              activeColor: AppColors.accentGold,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeMadhabEvent(val));
                  context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                  Navigator.pop(dialogCtx);
                }
              },
            ),
            RadioListTile<AppMadhab>(
              title: const Text('الحنفي'),
              subtitle: const Text('ظل الشيء مثليه'),
              value: AppMadhab.hanafi,
              groupValue: current,
              activeColor: AppColors.accentGold,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeMadhabEvent(val));
                  context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                  Navigator.pop(dialogCtx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final madhabName = state.madhab == AppMadhab.shafi
              ? 'الشافعي / المالكي / الحنبلي (المثل الأول)'
              : 'الحنفي (المثلين)';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              SettingsSectionCard(
                title: 'طريقة الحساب الفلكي والمذهب',
                children: [
                  SettingsTile(
                    icon: Icons.calculate_outlined,
                    title: 'طريقة الحساب',
                    subtitle: state.calculationMethod.displayNameArabic,
                    showDivider: true,
                    onTap: () => _showCalculationMethodDialog(context, state.calculationMethod),
                  ),
                  SettingsTile(
                    icon: Icons.menu_book_outlined,
                    title: 'المذهب الفقهي (صلاة العصر)',
                    subtitle: madhabName,
                    showDivider: false,
                    onTap: () => _showMadhabDialog(context, state.madhab),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Informative Note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تختلف زوايا الفجر والعشاء بحسب الهيئة المعتمدة في كل دولة، كما يؤثر المذهب الفقهي على تحديد بداية وقت صلاة العصر فقط.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
