import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_design_system.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

/// 3-segment ThemeMode control (Auto / Light / Dark) without deprecated RadioListTile.
class ThemeModeSegmentBar extends StatelessWidget {
  final ThemeMode currentMode;
  final bool forcesDark;
  final ValueChanged<ThemeMode> onChanged;

  const ThemeModeSegmentBar({
    super.key,
    required this.currentMode,
    required this.forcesDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final options = [
      (mode: ThemeMode.system, label: 'تلقائي', icon: Icons.brightness_auto_rounded),
      (mode: ThemeMode.light, label: 'نهاري', icon: Icons.light_mode_rounded),
      (mode: ThemeMode.dark, label: 'ليلي', icon: Icons.dark_mode_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: options.map((opt) {
              final effectiveSelected =
                  forcesDark ? opt.mode == ThemeMode.dark : currentMode == opt.mode;
              final disabled = forcesDark && opt.mode != ThemeMode.dark;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: disabled
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            onChanged(opt.mode);
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: effectiveSelected ? p.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            opt.icon,
                            size: 16,
                            color: effectiveSelected
                                ? p.onPrimary
                                : (disabled
                                    ? p.textSecondary.withValues(alpha: 0.4)
                                    : p.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            opt.label,
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 12.5,
                              fontWeight: effectiveSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: effectiveSelected
                                  ? p.onPrimary
                                  : (disabled
                                      ? p.textSecondary.withValues(alpha: 0.4)
                                      : p.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (forcesDark) ...[
          const SizedBox(height: 6),
          Text(
            'وضع الليلي الخالص (AMOLED) يعمل بالثيم الداكن دائماً لراحة العين',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'IBMPlexSansArabic',
              fontSize: 11,
              color: p.accentText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Visual 5-palette selector cards inspired by Golden Quran themes.
class ThemePalettePicker extends StatelessWidget {
  final AppColorPalette selectedPalette;
  final ValueChanged<AppColorPalette> onSelect;

  const ThemePalettePicker({
    super.key,
    required this.selectedPalette,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Column(
      children: AppColorPalette.values.map((item) {
        final isSelected = item == selectedPalette;
        final swatches = item.previewColors;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(item);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? p.primaryContainer : p.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? p.accent : p.border,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: AppDesignSystem.cardShadow(isDark: p.isDark),
                ),
                child: Row(
                  children: [
                    // 3 overlapping swatch circles
                    SizedBox(
                      width: 62,
                      height: 30,
                      child: Stack(
                        children: [
                          for (int i = 0; i < swatches.length; i++)
                            Positioned(
                              right: i * 16.0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: swatches[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: p.isDark ? Colors.white24 : Colors.black12,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.titleArabic,
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: p.textPrimary,
                            ),
                          ),
                          Text(
                            item.subtitleArabic,
                            style: TextStyle(
                              fontFamily: 'IBMPlexSansArabic',
                              fontSize: 11,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSelected
                          ? Icon(
                              Icons.check_circle_rounded,
                              key: ValueKey('sel_${item.name}'),
                              color: p.accent,
                              size: 22,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              key: ValueKey('unsel_${item.name}'),
                              color: p.border,
                              size: 22,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Modal bottom sheet allowing instant 1-tap theme & color-palette switching from Home.
class ThemeQuickPickerSheet extends StatelessWidget {
  const ThemeQuickPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    final settingsBloc = context.read<SettingsBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<SettingsBloc>.value(
        value: settingsBloc,
        child: const ThemeQuickPickerSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: p.border),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.palette_outlined, color: p.accent, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'مظهر وألوان التطبيق',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: p.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ThemeModeSegmentBar(
                  currentMode: state.themeMode,
                  forcesDark: state.colorPalette.forcesDarkMode,
                  onChanged: (mode) => context
                      .read<SettingsBloc>()
                      .add(ChangeThemeModeEvent(mode)),
                ),
                const SizedBox(height: 14),
                ThemePalettePicker(
                  selectedPalette: state.colorPalette,
                  onSelect: (palette) => context
                      .read<SettingsBloc>()
                      .add(ChangeColorPaletteEvent(palette)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
