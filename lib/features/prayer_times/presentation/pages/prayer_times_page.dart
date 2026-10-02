import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/skeleton_loading.dart';
import '../../../azkar/data/models/azkar_item_model.dart';
import '../../../azkar/presentation/bloc/azkar_bloc.dart';
import '../../../azkar/presentation/bloc/azkar_event.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../data/models/prayer_day_model.dart';
import '../bloc/prayer_bloc.dart';
import '../bloc/prayer_event.dart';
import '../bloc/prayer_state.dart';
import '../widgets/header_widget.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_list.dart';
import 'main_navigation_screen.dart';

class PrayerTimesPage extends StatelessWidget {
  const PrayerTimesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 58,
        centerTitle: true,
        // Right side (in RTL): Qibla Compass Icon only (clean, matching design)
        leading: IconButton(
          icon: const Icon(Icons.explore_outlined),
          tooltip: 'القبلة',
          onPressed: () {
            Navigator.of(context).push(
              FadeSlidePageRoute(page: const QiblaPage()),
            );
          },
        ),
        title: Text(
          'مواقيت الصلاة',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20.5,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF163A29),
          ),
        ),
        // Left side (in RTL): Settings Gear matching the Home page
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.of(context).push(
                FadeSlidePageRoute(page: const SettingsPage()),
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
                        const SizedBox(height: 20),
                        _buildSunnahTimesCard(
                          context: context,
                          prayerDay: state.prayerDay,
                          is24Hour: settingsState.is24HourFormat,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildPostPrayerCard(context, isDark),
                        const SizedBox(height: 20),
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

  Widget _buildSunnahTimesCard({
    required BuildContext context,
    required PrayerDayModel prayerDay,
    required bool is24Hour,
    required bool isDark,
  }) {
    final sunriseTime = prayerDay.sunrise.time;
    final duhaStartTime = sunriseTime.add(const Duration(minutes: 15));
    final maghribTime = prayerDay.maghrib.time;
    final nextFajrTime = prayerDay.fajr.time.add(const Duration(days: 1));
    final nightDuration = nextFajrTime.difference(maghribTime);
    final midnightTime = maghribTime.add(Duration(seconds: nightDuration.inSeconds ~/ 2));
    final lastThirdTime = nextFajrTime.subtract(Duration(seconds: nightDuration.inSeconds ~/ 3));

    final duhaFormatted = DateUtilsHelper.formatPrayerTime(duhaStartTime, is24Hour: is24Hour);
    final midnightFormatted = DateUtilsHelper.formatPrayerTime(midnightTime, is24Hour: is24Hour);
    final lastThirdFormatted = DateUtilsHelper.formatPrayerTime(lastThirdTime, is24Hour: is24Hour);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSunnahDetailsSheet(
          context: context,
          duhaFormatted: duhaFormatted,
          midnightFormatted: midnightFormatted,
          lastThirdFormatted: lastThirdFormatted,
          isDark: isDark,
        ),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFEFF2F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Chevron on the left (RTL end)
              const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
              const SizedBox(width: 10),

              // Green book icon container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B4D3E).withValues(alpha: 0.35)
                      : const Color(0xFFE2EFE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.menu_book_outlined,
                  color: isDark ? AppColors.accentGoldLight : const Color(0xFF163A29),
                  size: 22,
                ),
              ),

              const Spacer(),

              // Right side (RTL start): Title, Subtitle and Sparkles
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'أوقات السنن والنوافل والوتر',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF163A29),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 17,
                        color: Color(0xFFD4AF37),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'أوقات مستحبة للصلاة في اليوم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSunnahDetailsSheet({
    required BuildContext context,
    required String duhaFormatted,
    required String midnightFormatted,
    required String lastThirdFormatted,
    required bool isDark,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFEFF2F0),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 20, color: Color(0xFFD4AF37)),
                const SizedBox(width: 8),
                Text(
                  'أوقات السنن والنوافل والوتر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF163A29),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSunnahDetailRow(
              title: 'صلاة الضحى',
              time: duhaFormatted,
              subtitle: 'يبدأ وقتها بعد شروق الشمس بـ ١٥ دقيقة ويمتد حتى قبل الظهر',
              icon: Icons.wb_sunny_rounded,
              color: const Color(0xFFF59E0B),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildSunnahDetailRow(
              title: 'نصف الليل',
              time: midnightFormatted,
              subtitle: 'نهاية الوقت الاختياري لصلاة العشاء',
              icon: Icons.nights_stay_rounded,
              color: const Color(0xFF6366F1),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildSunnahDetailRow(
              title: 'الثلث الأخير من الليل',
              time: lastThirdFormatted,
              subtitle: 'وقت التنزل الإلهي وصلاة الوتر وقيام الليل',
              icon: Icons.nightlight_round,
              color: const Color(0xFFD4AF37),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunnahDetailRow({
    required String title,
    required String time,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFEFF2F0),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF163A29),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPrayerCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/serene_mihrab.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.black.withValues(alpha: 0.52),
                              AppColors.primaryDark.withValues(alpha: 0.72),
                            ]
                          : [
                              Colors.black.withValues(alpha: 0.40),
                              AppColors.primaryDark.withValues(alpha: 0.65),
                            ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: AppColors.accentGoldLight, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'أذكار ما بعد الصلاة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'الاستغفار والتسبيح دبر كل صلاة مكتوبة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.read<AzkarBloc>().add(const SelectCategoryEvent(AzkarCategory.postPrayer));
                      MainNavigationScreen.of(context)?.navigateToPage(2);
                    },
                    child: const Text(
                      'ابدأ الأذكار',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
