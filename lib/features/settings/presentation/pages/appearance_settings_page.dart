import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/theme_palette_picker.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: const Text('المظهر والألوان والوقت'),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              // 1. Live Mini Preview Card
              _buildLivePreviewCard(p, state),
              const SizedBox(height: 18),

              // 2. Day / Night Mode Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  'وضع الإضاءة',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
              ),
              ThemeModeSegmentBar(
                currentMode: state.themeMode,
                forcesDark: state.colorPalette.forcesDarkMode,
                onChanged: (mode) {
                  context.read<SettingsBloc>().add(ChangeThemeModeEvent(mode));
                },
              ),
              const SizedBox(height: 18),

              // 3. 5 Selectable Golden-Quran Color Palettes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  'أوضاع الألوان والهوية',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
              ),
              ThemePalettePicker(
                selectedPalette: state.colorPalette,
                onSelect: (palette) {
                  context
                      .read<SettingsBloc>()
                      .add(ChangeColorPaletteEvent(palette));
                },
              ),
              const SizedBox(height: 10),

              // 4. Time Format Setting
              SettingsSectionCard(
                title: 'تنسيق الساعة',
                children: [
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: p.isDark ? 0.14 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.access_time_outlined,
                        size: 20,
                        color: p.accent,
                      ),
                    ),
                    title: const Text(
                      'نظام 24 ساعة',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      state.is24HourFormat
                          ? 'مفعّل (مثال: 18:30)'
                          : 'معطّل (مثال: 06:30 م)',
                    ),
                    value: state.is24HourFormat,
                    activeThumbColor: p.accent,
                    onChanged: (val) {
                      context
                          .read<SettingsBloc>()
                          .add(Toggle24HourFormatEvent(val));
                      context
                          .read<PrayerBloc>()
                          .add(const RefreshPrayerTimesEvent());
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

  Widget _buildLivePreviewCard(WirdPalette p, SettingsState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDesignSystem.cardDecoration(
        isDark: p.isDark,
        palette: p,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: p.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: p.accent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'معاينة فورية • ${state.colorPalette.titleArabic}',
                  style: TextStyle(
                    fontFamily: 'IBMPlexSansArabic',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.accentText,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.auto_awesome_rounded, size: 18, color: p.accent),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: AppDesignSystem.dhikrTextContainerDecoration(
              isDark: p.isDark,
              isWarmParchment: true,
              palette: p,
            ),
            child: Text(
              '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 19,
                height: 1.85,
                color: p.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
