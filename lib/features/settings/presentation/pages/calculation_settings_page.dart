import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_tile.dart';
import 'adjustments_settings_page.dart';

class CalculationSettingsPage extends StatelessWidget {
  const CalculationSettingsPage({super.key});

  void _showCalculationMethodDialog(BuildContext context, AppCalculationMethod current) {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('طريقة حساب المواقيت', style: AppTypography.sectionHeader(p.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: AppCalculationMethod.values.map((method) {
              return RadioListTile<AppCalculationMethod>(
                title: Text(method.displayNameArabic, style: AppTypography.rowTitle(p.textPrimary)),
                value: method,
                groupValue: current,
                activeColor: p.primary,
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
    final p = context.palette;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('المذهب الفقهي (صلاة العصر)', style: AppTypography.sectionHeader(p.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppMadhab>(
              title: Text('الشافعي / المالكي / الحنبلي', style: AppTypography.rowTitle(p.textPrimary)),
              subtitle: Text('ظل الشيء مثله (الجمهور)', style: AppTypography.meta(p.textSecondary)),
              value: AppMadhab.shafi,
              groupValue: current,
              activeColor: p.primary,
              onChanged: (val) {
                if (val != null) {
                  context.read<SettingsBloc>().add(ChangeMadhabEvent(val));
                  context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                  Navigator.pop(dialogCtx);
                }
              },
            ),
            RadioListTile<AppMadhab>(
              title: Text('الحنفي', style: AppTypography.rowTitle(p.textPrimary)),
              subtitle: Text('ظل الشيء مثليه', style: AppTypography.meta(p.textSecondary)),
              value: AppMadhab.hanafi,
              groupValue: current,
              activeColor: p.primary,
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
    final p = context.palette;

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
              const SizedBox(height: 12),

              SettingsSectionCard(
                title: 'مطابقة توقيت المسجد المحلي',
                children: [
                  SettingsTile(
                    icon: Icons.tune_outlined,
                    title: 'تعديل المواقيت بالدقائق',
                    subtitle: (state.adjustFajr != 0 ||
                            state.adjustSunrise != 0 ||
                            state.adjustDhuhr != 0 ||
                            state.adjustAsr != 0 ||
                            state.adjustMaghrib != 0 ||
                            state.adjustIsha != 0)
                        ? 'تعديلات مفعّلة على بعض الصلوات'
                        : 'ضبط يدوي (±30 دقيقة) لكل صلاة عند الحاجة',
                    showDivider: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        FadeSlidePageRoute(page: const AdjustmentsSettingsPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Informative Note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.cardElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: p.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'تختلف زوايا الفجر والعشاء بحسب الهيئة المعتمدة في كل دولة، كما يؤثر المذهب الفقهي على تحديد بداية وقت صلاة العصر فقط.',
                        style: AppTypography.meta(p.textPrimary),
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
