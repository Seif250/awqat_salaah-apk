import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section_card.dart';

class AdjustmentsSettingsPage extends StatelessWidget {
  const AdjustmentsSettingsPage({super.key});

  Widget _buildAdjustmentRow(
    BuildContext context, {
    required String prayerName,
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
            prayerName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: value > -30 ? () => onChanged(value - 1) : null,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              SizedBox(
                width: 65,
                child: Text(
                  '${value >= 0 ? '+' : ''}$value د',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: value != 0 ? AppColors.accentGold : null,
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 16),
                onPressed: value < 30 ? () => onChanged(value + 1) : null,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المواقيت'),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final hasAdjustments = state.adjustFajr != 0 ||
              state.adjustSunrise != 0 ||
              state.adjustDhuhr != 0 ||
              state.adjustAsr != 0 ||
              state.adjustMaghrib != 0 ||
              state.adjustIsha != 0;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              SettingsSectionCard(
                title: 'تعديل أوقات الصلاة بالدقائق (±30 دقيقة)',
                children: [
                  _buildAdjustmentRow(
                    context,
                    prayerName: 'الفجر',
                    value: state.adjustFajr,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(fajr: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildAdjustmentRow(
                    context,
                    prayerName: 'الشروق',
                    value: state.adjustSunrise,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(sunrise: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildAdjustmentRow(
                    context,
                    prayerName: 'الظهر',
                    value: state.adjustDhuhr,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(dhuhr: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildAdjustmentRow(
                    context,
                    prayerName: 'العصر',
                    value: state.adjustAsr,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(asr: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildAdjustmentRow(
                    context,
                    prayerName: 'المغرب',
                    value: state.adjustMaghrib,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(maghrib: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                  _buildAdjustmentRow(
                    context,
                    prayerName: 'العشاء',
                    value: state.adjustIsha,
                    showDivider: false,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(UpdateAdjustmentsEvent(isha: val));
                      context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (hasAdjustments) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
                  label: const Text('إعادة ضبط كافة التعديلات إلى الصفر', style: TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    context.read<SettingsBloc>().add(
                          const UpdateAdjustmentsEvent(
                            fajr: 0,
                            sunrise: 0,
                            dhuhr: 0,
                            asr: 0,
                            maghrib: 0,
                            isha: 0,
                          ),
                        );
                    context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                  },
                ),
                const SizedBox(height: 16),
              ],

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
                        'يمكنك تعديل أي صلاة بتقديمها أو تأخيرها لمطابقة توقيت المسجد المحلي في منطقتك بدقة.',
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
