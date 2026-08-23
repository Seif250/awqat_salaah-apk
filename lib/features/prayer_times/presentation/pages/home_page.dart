import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../bloc/prayer_bloc.dart';
import '../bloc/prayer_event.dart';
import '../bloc/prayer_state.dart';
import '../widgets/header_widget.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_list.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'أوقات الصلاة',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return BlocConsumer<PrayerBloc, PrayerState>(
            listener: (context, state) {
              if (state is PrayerError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is PrayerLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accentGold),
                );
              }

              if (state is PrayerLoaded) {
                return RefreshIndicator(
                  color: AppColors.accentGold,
                  onRefresh: () async {
                    context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header with Location & Dates
                        HeaderWidget(
                          cityName: state.cityName,
                          countryName: state.countryName,
                          onLocationTap: () async {
                            await LocationPickerSheet.show(context);
                            if (context.mounted) {
                              context
                                  .read<PrayerBloc>()
                                  .add(const RefreshPrayerTimesEvent());
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Large Next Prayer Card with Live Countdown
                        NextPrayerCard(
                          prayerDay: state.prayerDay,
                          remainingDuration: state.remainingDuration,
                          is24Hour: settingsState.is24HourFormat,
                        ),
                        const SizedBox(height: 24),

                        // Prayer Times List (Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha)
                        PrayerList(
                          prayerDay: state.prayerDay,
                          is24Hour: settingsState.is24HourFormat,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text('حدث خطأ في تحميل مواقيت الصلاة'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<PrayerBloc>().add(const LoadPrayerTimesEvent());
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
