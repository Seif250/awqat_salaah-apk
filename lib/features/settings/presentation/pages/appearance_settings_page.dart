import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

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

  void _showThemeDialog(BuildContext context, ThemeMode current) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('مظهر التطبيق'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('تلقائي (حسب النظام)'),
              value: ThemeMode.system,
              groupValue: current,
              activeColor: AppColors.accentGold,
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
              activeColor: AppColors.accentGold,
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
              activeColor: AppColors.accentGold,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المظهر والوقت'),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              SettingsSectionCard(
                title: 'المظهر وتنسيق الوقت',
                children: [
                  SettingsTile(
                    icon: Icons.palette_outlined,
                    title: 'المظهر',
                    subtitle: _getThemeName(state.themeMode),
                    showDivider: true,
                    onTap: () => _showThemeDialog(context, state.themeMode),
                  ),
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withValues(alpha: isDark ? 0.12 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.access_time_outlined, size: 20, color: AppColors.accentGold),
                    ),
                    title: const Text('نظام 24 ساعة', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(state.is24HourFormat ? 'مفعّل (مثال: 18:30)' : 'معطّل (مثال: 06:30 م)'),
                    value: state.is24HourFormat,
                    activeColor: AppColors.accentGold,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(Toggle24HourFormatEvent(val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
