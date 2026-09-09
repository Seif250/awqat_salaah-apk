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

import '../../../../services/notification_service.dart';
import '../../../azkar/data/models/azkar_item_model.dart';
import '../../../azkar/presentation/bloc/azkar_bloc.dart';
import '../../../azkar/presentation/bloc/azkar_state.dart';
import '../../../azkar/presentation/pages/azkar_page.dart';
import 'main_navigation_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermissions();
    });
  }

  void _checkNotificationPermissions() async {
    if (!mounted) return;
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState.notificationsEnabled) {
      final ns = NotificationService();
      final enabled = await ns.areNotificationsEnabled();
      if (!enabled) {
        await ns.requestNotificationsPermission();
      }
    }
  }

  void _navigateToAzkar(BuildContext context) {
    final mainNav = MainNavigationScreen.of(context);
    if (mainNav != null) {
      mainNav.navigateToPage(1);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AzkarPage()),
      );
    }
  }

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
            icon: const Icon(Icons.auto_stories_rounded, color: AppColors.accentGold),
            tooltip: 'الأذكار والورد اليومي',
            onPressed: () => _navigateToAzkar(context),
          ),
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
                        const SizedBox(height: 18),

                        // Quick Azkar Ward Card
                        BlocBuilder<AzkarBloc, AzkarState>(
                          builder: (context, azkarState) {
                            if (azkarState is! AzkarLoaded) return const SizedBox.shrink();
                            final isAllDone = azkarState.totalCategoryCount > 0 &&
                                azkarState.completedCategoryCount >= azkarState.totalCategoryCount;

                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          AppColors.darkCard,
                                          AppColors.primaryDark.withValues(alpha: 0.5),
                                        ]
                                      : [
                                          AppColors.lightCard,
                                          AppColors.primaryContainer.withValues(alpha: 0.3),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isAllDone
                                      ? AppColors.primaryLight.withValues(alpha: 0.5)
                                      : AppColors.accentGold.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => _navigateToAzkar(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          azkarState.selectedCategory.iconAssetOrEmoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'الورد الحالي: ${azkarState.selectedCategory.titleArabic}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (isAllDone) ...[
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.check_circle_rounded,
                                                        color: AppColors.primaryLight, size: 16),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isAllDone
                                                    ? 'اكتمل الورد بحمد الله 🌿'
                                                    : 'أنجزت ${azkarState.completedCategoryCount} من ${azkarState.totalCategoryCount} أذكار • اضغط للمتابعة',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white60 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded,
                                            size: 16, color: AppColors.accentGold),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

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
