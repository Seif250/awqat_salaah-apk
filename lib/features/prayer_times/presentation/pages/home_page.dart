import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/prayer_phase_glyph.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/skeleton_loading.dart';
import '../../../azkar/data/models/azkar_item_model.dart';
import '../../../azkar/presentation/bloc/azkar_bloc.dart';
import '../../../azkar/presentation/bloc/azkar_event.dart';
import '../../../azkar/presentation/bloc/azkar_state.dart';
import '../../../azkar/presentation/widgets/digital_tasbih_sheet.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../../../quran/services/daily_ayah_service.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../settings/presentation/widgets/theme_palette_picker.dart';
import '../bloc/prayer_bloc.dart';
import '../bloc/prayer_event.dart';
import '../bloc/prayer_state.dart';
import '../../data/models/prayer_time_model.dart';
import '../widgets/header_widget.dart';
import '../widgets/next_prayer_card.dart';
import 'main_navigation_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _navigateToTab(int index) {
    final mainNav = MainNavigationScreen.of(context);
    if (mainNav != null) {
      mainNav.navigateToPage(index);
    }
  }

  void _navigateToAzkarCategory(AzkarCategory category) {
    context.read<AzkarBloc>().add(SelectCategoryEvent(category));
    _navigateToTab(2);
  }

  ({String label, IconData icon, AzkarCategory recommendedCategory}) _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return (
        label: 'صباح الذكر',
        icon: Icons.wb_sunny_outlined,
        recommendedCategory: AzkarCategory.morning,
      );
    } else if (hour >= 12 && hour < 19) {
      return (
        label: 'مساء السكينة',
        icon: Icons.wb_twilight_outlined,
        recommendedCategory: AzkarCategory.evening,
      );
    } else if (hour >= 19 && hour <= 23) {
      return (
        label: 'سكينة الليل',
        icon: Icons.bedtime_outlined,
        recommendedCategory: AzkarCategory.sleep,
      );
    }
    return (
      label: 'وقت الأسحار',
      icon: Icons.nightlight_round,
      recommendedCategory: AzkarCategory.qiyam,
    );
  }

  void _openDigitalTasbih(BuildContext context) {
    final azkarBloc = context.read<AzkarBloc>();
    final azkarState = azkarBloc.state;
    final initialCount = azkarState is AzkarLoaded ? azkarState.dailyProgress.freeTasbihCount : 0;

    DigitalTasbihSheet.show(
      context,
      initialCount: initialCount,
      onCountChanged: (delta) {
        azkarBloc.add(UpdateFreeTasbihEvent(delta));
      },
      onReset: () {
        azkarBloc.add(const ResetFreeTasbihEvent());
      },
    );
  }

  Future<void> _shareDailyAyah(BuildContext context, DailyAyah ayah) async {
    final text = '﴿ ${ayah.text} ﴾\n\n'
        'سورة ${ayah.surahName} • الآية ${toArabicDigits(ayah.ayahId)}\n'
        '— تطبيق ${AppConstants.appName}';
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'آية اليوم - سورة ${ayah.surahName}'),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        AppSnackBar.showInfo(context, 'تم نسخ الآية إلى الحافظة');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;
    final greeting = _timeGreeting();
    final horizontalPad = AppDesignSystem.pageHorizontalPadding(context);

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        titleSpacing: horizontalPad,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConstants.appName,
              style: AppTypography.pageTitle(p.textPrimary).copyWith(
                fontSize: 21,
              ),
            ),
            Text(
              AppConstants.appSubtitle,
              style: AppTypography.meta(p.textSecondary, size: 11.5),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  greeting.icon,
                  size: 15,
                  color: p.accent,
                ),
                const SizedBox(width: 4),
                Text(
                  greeting.label,
                  style: AppTypography.meta(p.textSecondary, size: 11.5)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'مظهر الألوان',
            onPressed: () => ThemeQuickPickerSheet.show(context),
          ),
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

              if (state is! PrayerLoaded) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: p.accent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'تعذر تحميل بيانات المواقيت',
                          style: AppTypography.rowTitle(p.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<PrayerBloc>()
                              .add(const RefreshPrayerTimesEvent()),
                          child: Text(
                            'إعادة المحاولة',
                            style: AppTypography.meta(p.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: p.accent,
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
                      // Unified Location & Dates Header
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
                      const SizedBox(height: 10),

                      // HERO SURFACE (Focal Point): Current / Next Prayer
                      NextPrayerCard(
                        prayerDay: state.prayerDay,
                        remainingDuration: state.remainingDuration,
                        is24Hour: settingsState.is24HourFormat,
                      ),
                      const SizedBox(height: 22),

                      // OPEN SECTION 1: Daily Wird Progress Strip
                      _buildDailyWirdCard(
                        context: context,
                        isDark: isDark,
                        recommendedCategory: greeting.recommendedCategory,
                      ),
                      const SizedBox(height: 16),
                      AppDesignSystem.hairlineDivider(p),
                      const SizedBox(height: 18),

                      // OPEN SECTION 2: Responsive Prayer Times Timeline
                      _buildPrayerTimesSection(
                        context: context,
                        state: state,
                        is24Hour: settingsState.is24HourFormat,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      AppDesignSystem.hairlineDivider(p),
                      const SizedBox(height: 18),

                      // OPEN SECTION 3: Quick Adhkar Row
                      _buildQuickAzkarSection(context),
                      const SizedBox(height: 16),
                      AppDesignSystem.hairlineDivider(p),
                      const SizedBox(height: 14),

                      // OPEN SECTION 4: Qibla & Digital Tasbih Split Row
                      _buildUtilityRow(context: context, isDark: isDark),
                      const SizedBox(height: 18),

                      // Existing Daily Ayah section (content preserved untouched)
                      _buildDailyAyahSection(context, isDark),
                      const SizedBox(height: 12),
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

  Widget _buildDailyWirdCard({
    required BuildContext context,
    required bool isDark,
    required AzkarCategory recommendedCategory,
  }) {
    return BlocBuilder<AzkarBloc, AzkarState>(
      builder: (context, azkarState) {
        final p = context.palette;
        final double morningRate =
            azkarState is AzkarLoaded ? azkarState.morningCompletionRate : 0.0;
        final double eveningRate =
            azkarState is AzkarLoaded ? azkarState.eveningCompletionRate : 0.0;
        final int todayTasbih = azkarState is AzkarLoaded
            ? azkarState.dailyProgress.freeTasbihCount +
                azkarState.dailyProgress.itemCounts.values
                    .fold<int>(0, (sum, v) => sum + v)
            : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final isCompact = constraints.maxWidth < 310 || textScale > 1.2;

              final ringsAndSummary = Row(
                children: [
                  _buildWirdRing(
                    label: 'الصباح',
                    progress: morningRate,
                    color: p.accent,
                    palette: p,
                  ),
                  const SizedBox(width: 10),
                  _buildWirdRing(
                    label: 'المساء',
                    progress: eveningRate,
                    color: p.primary,
                    palette: p,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ملخص وردك اليومي',
                          style: AppTypography.rowTitle(
                            p.textPrimary,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'تسبيح اليوم: ${toArabicDigits(todayTasbih)}',
                          style: AppTypography.meta(p.textSecondary, size: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionButton = TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: p.primaryContainer,
                  foregroundColor: p.accentText,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(48, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _navigateToAzkarCategory(recommendedCategory),
                child: Text(
                  'متابعة الورد',
                  style: AppTypography.label(p.accentText, size: 12),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ringsAndSummary,
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: actionButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: ringsAndSummary),
                  const SizedBox(width: 8),
                  actionButton,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWirdRing({
    required String label,
    required double progress,
    required Color color,
    required WirdPalette palette,
  }) {
    final pct = (progress * 100).round().clamp(0, 100);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 3.2,
                backgroundColor: palette.primaryContainer,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                '${toArabicDigits(pct)}٪',
                style: AppTypography.timeValue(
                  palette.textPrimary,
                  size: 10.5,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.meta(palette.textSecondary, size: 10.5),
        ),
      ],
    );
  }

  /// Responsive Open Prayer Times Section (adapts automatically on narrow screens & large text scales)
  Widget _buildPrayerTimesSection({
    required BuildContext context,
    required PrayerLoaded state,
    required bool is24Hour,
    required bool isDark,
  }) {
    final pal = context.palette;
    final prayers = state.prayerDay.prayerTimesOnly;
    final currentFocusType = state.prayerDay.focusPrayerType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'مواقيت الصلاة',
                style: AppTypography.sectionHeader(pal.textPrimary),
              ),
              InkWell(
                onTap: () => _navigateToTab(1),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'عرض جميع المواقيت',
                          style: AppTypography.label(pal.accentText, size: 12.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 11,
                        color: pal.accentText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final useSingleRow = constraints.maxWidth >= 340 && textScale <= 1.18;

            Widget buildPrayerCell(PrayerTimeModel prayer,
                {double? fixedWidth}) {
              final isNext = prayer.type == currentFocusType;
              final timeFormatted = DateUtilsHelper.formatPrayerTime(
                prayer.time,
                is24Hour: is24Hour,
              );

              final content = Container(
                width: fixedWidth,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isNext ? pal.cardElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrayerPhaseGlyph(
                      type: prayer.type,
                      color: isNext ? pal.accentText : pal.textSecondary,
                      accentColor: isNext
                          ? pal.accent.withValues(alpha: 0.25)
                          : pal.textSecondary.withValues(alpha: 0.14),
                      size: 16,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      prayer.type.nameArabic,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.meta(
                        isNext ? pal.accentText : pal.textSecondary,
                        size: 12,
                        weight: isNext ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeFormatted,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: AppTypography.timeValue(
                        isNext ? pal.textPrimary : pal.textPrimary.withValues(alpha: 0.85),
                        size: 12.5,
                        weight: isNext ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isNext ? pal.accent : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );

              return fixedWidth != null ? content : Expanded(child: content);
            }

            if (useSingleRow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: prayers.map((p) => buildPrayerCell(p)).toList(),
              );
            }

            final cols = (constraints.maxWidth < 300 || textScale > 1.35) ? 2 : 3;
            final cellWidth =
                (constraints.maxWidth - (cols - 1) * 8) / cols;

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: prayers
                  .map((p) => buildPrayerCell(p, fixedWidth: cellWidth))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  /// Open Quick Adhkar Row (light circular glyphs directly on page)
  Widget _buildQuickAzkarSection(BuildContext context) {
    final p = context.palette;
    final quickItems = [
      (
        title: 'أذكار الصباح',
        cat: AzkarCategory.morning,
        icon: Icons.wb_sunny_outlined,
      ),
      (
        title: 'أذكار المساء',
        cat: AzkarCategory.evening,
        icon: Icons.nights_stay_outlined,
      ),
      (
        title: 'أذكار النوم',
        cat: AzkarCategory.sleep,
        icon: Icons.bedtime_outlined,
      ),
      (
        title: 'التسبيح',
        cat: AzkarCategory.general,
        icon: Icons.flare_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'الأذكار اليومية',
                style: AppTypography.sectionHeader(p.textPrimary),
              ),
              InkWell(
                onTap: () => _navigateToTab(2),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'عرض الكل',
                          style: AppTypography.label(p.accentText, size: 12.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 11,
                        color: p.accentText,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1.0);
            final useSingleRow = constraints.maxWidth >= 330 && textScale <= 1.2;

            Widget buildQuickBtn(
                ({String title, AzkarCategory cat, IconData icon}) item,
                {double? width}) {
              final child = InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _navigateToAzkarCategory(item.cat),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.primaryContainer,
                        ),
                        child: Icon(
                          item.icon,
                          size: 21,
                          color: p.accentText,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta(
                          p.textPrimary,
                          size: 12,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              return width != null
                  ? SizedBox(width: width, child: child)
                  : Expanded(child: child);
            }

            if (useSingleRow) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: quickItems.map((it) => buildQuickBtn(it)).toList(),
              );
            }

            final itemW = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 6,
              children:
                  quickItems.map((it) => buildQuickBtn(it, width: itemW)).toList(),
            );
          },
        ),
      ],
    );
  }

  /// Open Split Utility Strip (Qibla + Digital Tasbih without heavy boxed cards)
  Widget _buildUtilityRow({
    required BuildContext context,
    required bool isDark,
  }) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final stackVertical = constraints.maxWidth < 310 || textScale > 1.3;

        final qiblaTile = _buildUtilityTile(
          palette: p,
          icon: Icons.explore_outlined,
          title: 'اتجاه القبلة',
          subtitle: 'بوصلة الكعبة',
          iconColor: p.accentText,
          onTap: () {
            Navigator.push(
              context,
              FadeSlidePageRoute(page: const QiblaPage()),
            );
          },
        );

        final tasbihTile = _buildUtilityTile(
          palette: p,
          icon: Icons.fingerprint_rounded,
          title: 'المسبحة الإلكترونية',
          subtitle: 'تسبيح حر سريع',
          iconColor: p.accent,
          onTap: () => _openDigitalTasbih(context),
        );

        if (stackVertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              qiblaTile,
              AppDesignSystem.hairlineDivider(p),
              tasbihTile,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: qiblaTile),
              Container(
                width: 0.75,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                color: p.hairline,
              ),
              Expanded(child: tasbihTile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUtilityTile({
    required WirdPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.rowTitle(
                        palette.textPrimary,
                        weight: FontWeight.w700,
                      ).copyWith(fontSize: 13.5),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.meta(
                        palette.textSecondary,
                        size: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// LEVEL 3: Mushaf-Styled Daily Ayah Reflection
  Widget _buildDailyAyahSection(BuildContext context, bool isDark) {
    final p = context.palette;
    final dailyAyah = DailyAyahService.instance.getTodayAyah();

    return Container(
      decoration: BoxDecoration(
        color: p.quranParchmentBg,
        borderRadius: AppDesignSystem.borderCard,
        border: Border.all(
          color: p.quranParchmentBorder,
          width: 1,
        ),
        boxShadow: AppDesignSystem.cardShadow(isDark: p.isDark),
      ),
      child: ClipRRect(
        borderRadius: AppDesignSystem.borderCard,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: p.isDark ? 0.10 : 0.08,
                child: Image.asset(
                  'assets/images/azkar_dua.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 36), // Balance share icon on opposite side
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'آية اليوم',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: p.isDark ? p.accentLight : p.accent,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (p.isDark ? p.accent : p.primary)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                dailyAyah.theme,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: p.isDark ? p.accentLight : p.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 18),
                        tooltip: 'مشاركة الآية',
                        color: p.isDark ? p.accentLight : p.primary,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        padding: EdgeInsets.zero,
                        onPressed: () => _shareDailyAyah(context, dailyAyah),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '﴿ ${dailyAyah.text} ﴾',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 19.5,
                      height: 1.9,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سورة ${dailyAyah.surahName} • الآية ${toArabicDigits(dailyAyah.ayahId)} • صفحة ${toArabicDigits(dailyAyah.page)}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      color: p.textSecondary,
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
