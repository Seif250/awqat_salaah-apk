import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../../core/theme/app_typography.dart';
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
import '../widgets/monthly_prayer_calendar_sheet.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_list.dart';
import 'main_navigation_screen.dart';

class PrayerTimesPage extends StatelessWidget {
  const PrayerTimesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final horizontalPad = AppDesignSystem.pageHorizontalPadding(context);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: true,
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
          style: AppTypography.pageTitle(p.textPrimary),
        ),
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
                  color: p.primary,
                  onRefresh: () async {
                    context
                        .read<PrayerBloc>()
                        .add(const RefreshPrayerTimesEvent());
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      4,
                      horizontalPad,
                      28,
                    ),
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
                        const SizedBox(height: 12),
                        NextPrayerCard(
                          prayerDay: state.prayerDay,
                          remainingDuration: state.remainingDuration,
                          is24Hour: settingsState.is24HourFormat,
                        ),
                        const SizedBox(height: 22),
                        PrayerList(
                          prayerDay: state.prayerDay,
                          is24Hour: settingsState.is24HourFormat,
                          onCalendarTap: () => MonthlyPrayerCalendarSheet.show(
                            context,
                            cityName: state.cityName,
                            countryName: state.countryName,
                            is24Hour: settingsState.is24HourFormat,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(height: 0.75, color: p.hairline),
                        const SizedBox(height: 18),
                        _buildSunnahTimesSection(
                          context: context,
                          prayerDay: state.prayerDay,
                          is24Hour: settingsState.is24HourFormat,
                          palette: p,
                        ),
                        const SizedBox(height: 18),
                        Container(height: 0.75, color: p.hairline),
                        const SizedBox(height: 16),
                        _buildPostPrayerActionRow(context, p),
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
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: p.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تعذر تحميل مواقيت الصلاة',
                        style: AppTypography.sectionHeader(p.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى التأكد من تشغيل خدمة الموقع وإعادة المحاولة',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(p.textSecondary, size: 13.5),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<PrayerBloc>()
                              .add(const RefreshPrayerTimesEvent());
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
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

  /// Open, non-boxed Sunnah & Nawafil times strip that adapts to narrow screens and font scaling.
  Widget _buildSunnahTimesSection({
    required BuildContext context,
    required PrayerDayModel prayerDay,
    required bool is24Hour,
    required WirdPalette palette,
  }) {
    final sunriseTime = prayerDay.sunrise.time;
    final duhaStartTime = sunriseTime.add(const Duration(minutes: 15));
    final maghribTime = prayerDay.maghrib.time;
    final nextFajrTime = prayerDay.fajr.time.add(const Duration(days: 1));
    final nightDuration = nextFajrTime.difference(maghribTime);
    final midnightTime =
        maghribTime.add(Duration(seconds: nightDuration.inSeconds ~/ 2));
    final lastThirdTime =
        nextFajrTime.subtract(Duration(seconds: nightDuration.inSeconds ~/ 3));

    final duhaFormatted =
        DateUtilsHelper.formatPrayerTime(duhaStartTime, is24Hour: is24Hour);
    final midnightFormatted =
        DateUtilsHelper.formatPrayerTime(midnightTime, is24Hour: is24Hour);
    final lastThirdFormatted =
        DateUtilsHelper.formatPrayerTime(lastThirdTime, is24Hour: is24Hour);

    return InkWell(
      onTap: () => _showSunnahDetailsSheet(
        context: context,
        duhaFormatted: duhaFormatted,
        midnightFormatted: midnightFormatted,
        lastThirdFormatted: lastThirdFormatted,
        palette: palette,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أوقات السنن والنوافل والوتر',
                    style: AppTypography.sectionHeader(palette.textPrimary),
                  ),
                ),
                Text(
                  'التفاصيل',
                  style: AppTypography.label(palette.accentText, size: 12),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_left_rounded,
                  color: palette.accentText,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                final isCompact =
                    constraints.maxWidth < 330 || textScale > 1.2;

                final items = [
                  (
                    label: 'الضحى',
                    time: duhaFormatted,
                    accent: palette.sunrise,
                  ),
                  (
                    label: 'نصف الليل',
                    time: midnightFormatted,
                    accent: palette.iqamah,
                  ),
                  (
                    label: 'الثلث الأخير',
                    time: lastThirdFormatted,
                    accent: palette.accentText,
                  ),
                ];

                if (isCompact) {
                  return Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    children: items
                        .map(
                          (item) => SizedBox(
                            width: (constraints.maxWidth - 20) / 2,
                            child: _buildOpenSunnahMetric(
                              label: item.label,
                              time: item.time,
                              accentColor: item.accent,
                              palette: palette,
                            ),
                          ),
                        )
                        .toList(),
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        Expanded(
                          child: _buildOpenSunnahMetric(
                            label: items[i].label,
                            time: items[i].time,
                            accentColor: items[i].accent,
                            palette: palette,
                          ),
                        ),
                        if (i < items.length - 1)
                          Container(
                            width: 0.75,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: palette.hairline,
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenSunnahMetric({
    required String label,
    required String time,
    required Color accentColor,
    required WirdPalette palette,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.meta(palette.textSecondary, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: AppTypography.timeValue(
              palette.textPrimary,
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showSunnahDetailsSheet({
    required BuildContext context,
    required String duhaFormatted,
    required String midnightFormatted,
    required String lastThirdFormatted,
    required WirdPalette palette,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'أوقات السنن والنوافل والوتر',
              style: AppTypography.sectionHeader(palette.textPrimary)
                  .copyWith(fontSize: 17),
            ),
            const SizedBox(height: 16),
            _buildSunnahDetailRow(
              title: 'صلاة الضحى',
              time: duhaFormatted,
              subtitle:
                  'يبدأ وقتها بعد شروق الشمس بـ ١٥ دقيقة ويمتد حتى قبل الظهر',
              icon: Icons.wb_sunny_outlined,
              color: palette.sunrise,
              palette: palette,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(height: 0.75, color: palette.hairline),
            ),
            _buildSunnahDetailRow(
              title: 'نصف الليل',
              time: midnightFormatted,
              subtitle: 'نهاية الوقت الاختياري لصلاة العشاء',
              icon: Icons.nights_stay_outlined,
              color: palette.iqamah,
              palette: palette,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Container(height: 0.75, color: palette.hairline),
            ),
            _buildSunnahDetailRow(
              title: 'الثلث الأخير من الليل',
              time: lastThirdFormatted,
              subtitle: 'وقت التنزل الإلهي وصلاة الوتر وقيام الليل',
              icon: Icons.nightlight_outlined,
              color: palette.accentText,
              palette: palette,
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
    required WirdPalette palette,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.rowTitle(palette.textPrimary),
                ),
                Text(
                  subtitle,
                  style: AppTypography.meta(palette.textSecondary, size: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: AppTypography.timeValue(
              palette.textPrimary,
              size: 14.5,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Calm open-tint action strip for post-prayer adhkar (replaces dark blurred image box)
  Widget _buildPostPrayerActionRow(
    BuildContext context,
    WirdPalette palette,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context
            .read<AzkarBloc>()
            .add(const SelectCategoryEvent(AzkarCategory.postPrayer));
        MainNavigationScreen.of(context)?.navigateToPage(2);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final isCompact = constraints.maxWidth < 290 || textScale > 1.2;

            final infoRow = Row(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: palette.accentText,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'أذكار ما بعد الصلاة',
                    style: AppTypography.rowTitle(
                      palette.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );

            final trailingAction = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ابدأ الأذكار',
                  style: AppTypography.label(palette.accentText, size: 12.5),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_left_rounded,
                  color: palette.accentText,
                  size: 18,
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  infoRow,
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailingAction,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: infoRow),
                const SizedBox(width: 8),
                trailingAction,
              ],
            );
          },
        ),
      ),
    );
  }
}
