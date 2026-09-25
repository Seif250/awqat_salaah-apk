import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/skeleton_loading.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../bloc/prayer_bloc.dart';
import '../bloc/prayer_event.dart';
import '../bloc/prayer_state.dart';
import '../widgets/header_widget.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_list.dart';

class PrayerTimesPage extends StatelessWidget {
  const PrayerTimesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 50,
        title: Text(
          'مواقيت الصلاة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined, size: 21),
            tooltip: 'اتجاه القبلة',
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            onPressed: () {
              Navigator.of(context).push(
                FadeSlidePageRoute(page: const QiblaPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 21),
            tooltip: 'الإعدادات',
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            onPressed: () {
              Navigator.of(context).push(
                FadeSlidePageRoute(page: const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return BlocConsumer<PrayerBloc, PrayerState>(
            listener: (context, state) {
              if (state is PrayerError) {
                AppSnackBar.showError(context, 'خطأ: ${state.message}');
              }
            },
            builder: (context, state) {
              if (state is PrayerLoading) {
                return const HomeSkeleton();
              }

              if (state is PrayerLoaded) {
                return RefreshIndicator(
                  color: AppColors.accentGold,
                  onRefresh: () async {
                    context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        NextPrayerCard(
                          prayerDay: state.prayerDay,
                          remainingDuration: state.remainingDuration,
                          is24Hour: settingsState.is24HourFormat,
                        ),
                        const SizedBox(height: 24),
                        PrayerList(
                          prayerDay: state.prayerDay,
                          is24Hour: settingsState.is24HourFormat,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              }

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: AppColors.accentGold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تعذر تحميل مواقيت الصلاة',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى التأكد من تشغيل خدمة الموقع وإعادة المحاولة',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<PrayerBloc>()
                              .add(const RefreshPrayerTimesEvent());
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
