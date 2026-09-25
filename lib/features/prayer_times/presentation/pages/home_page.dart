import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/prayer_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../core/utils/skeleton_loading.dart';
import '../../../azkar/data/models/azkar_item_model.dart';
import '../../../azkar/presentation/bloc/azkar_bloc.dart';
import '../../../azkar/presentation/bloc/azkar_event.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../quran/presentation/bloc/quran_bloc.dart';
import '../../../quran/presentation/bloc/quran_state.dart';
import '../../../quran/presentation/pages/surah_detail_page.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../bloc/prayer_bloc.dart';
import '../bloc/prayer_event.dart';
import '../bloc/prayer_state.dart';
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
    _navigateToTab(3);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'وِرد',
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              'صلاتك، قرآنك، ذكرك',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accentGold,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
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

              if (state is! PrayerLoaded) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: AppColors.accentGold,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'تعذر تحميل بيانات المواقيت',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<PrayerBloc>()
                              .add(const RefreshPrayerTimesEvent()),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.accentGold,
                onRefresh: () async {
                  context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LOCATION AND DATE (Compact section)
                      _buildLocationAndDate(
                        cityName: state.cityName,
                        countryName: state.countryName,
                        isDark: isDark,
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

                      // LEVEL 1 — PRIMARY: Current / Next Prayer Hero Card
                      NextPrayerCard(
                        prayerDay: state.prayerDay,
                        remainingDuration: state.remainingDuration,
                        is24Hour: settingsState.is24HourFormat,
                      ),
                      const SizedBox(height: 20),

                      // LEVEL 2 — IMPORTANT: Quran Continuation Section
                      BlocBuilder<QuranBloc, QuranState>(
                        builder: (context, quranState) {
                          return _buildQuranSection(
                            context: context,
                            quranState: quranState,
                            isDark: isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // LEVEL 2 — IMPORTANT: Prayer Times Section
                      _buildPrayerTimesSection(
                        context: context,
                        state: state,
                        is24Hour: settingsState.is24HourFormat,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // LEVEL 3 — SECONDARY: Quick Adhkar Row
                      _buildQuickAzkarSection(isDark),
                      const SizedBox(height: 12),

                      // LEVEL 3 — SECONDARY: Qibla Utility
                      _buildQiblaTile(context: context, isDark: isDark),
                      const SizedBox(height: 20),

                      // LEVEL 3 — SECONDARY: Daily Ayah Reflection
                      _buildDailyAyahSection(context, isDark),
                      const SizedBox(height: 16),
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

  /// Compact Location & Date Row
  Widget _buildLocationAndDate({
    required String cityName,
    required String countryName,
    required bool isDark,
    required VoidCallback onLocationTap,
  }) {
    final now = DateTime.now();
    final gregorianDate = DateUtilsHelper.getGregorianDateFormatted(now, locale: 'ar');
    final hijriDate = DateUtilsHelper.getHijriDateFormatted(now, locale: 'ar');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // City Selector
          InkWell(
            onTap: onLocationTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.accentGold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$cityName، $countryName',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),

          // Hijri and Gregorian Dates
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hijriDate,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                gregorianDate,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// LEVEL 2: Quran Continuation Section (Clean, subtle surface, not a huge card)
  Widget _buildQuranSection({
    required BuildContext context,
    required QuranState quranState,
    required bool isDark,
  }) {
    final hasLastRead = quranState is QuranLoaded && quranState.lastRead != null;
    final lastRead = hasLastRead ? quranState.lastRead : null;
    final page = lastRead?.page ?? 1;
    final progress = (page / 604.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'القرآن الكريم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              InkWell(
                onTap: () => _navigateToTab(1),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'فتح المصحف',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 11,
                        color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Continuation Surface
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                if (lastRead != null && quranState is QuranLoaded) {
                  final surah = quranState.allSurahs.firstWhere(
                    (s) => s.id == lastRead.surahId,
                    orElse: () => quranState.allSurahs.first,
                  );
                  Navigator.push(
                    context,
                    FadeSlidePageRoute(
                      page: SurahDetailPage(
                        surah: surah,
                        initialAyah: lastRead.ayahId,
                      ),
                    ),
                  );
                } else {
                  _navigateToTab(1);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Subtle Icon Container
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primary.withValues(alpha: 0.25)
                                : AppColors.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 22,
                            color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Surah & Ayah Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasLastRead
                                    ? 'سورة ${lastRead!.surahName} • آية ${toArabicDigits(lastRead.ayahId)}'
                                    : 'ابدأ تلاوة القرآن',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hasLastRead
                                    ? 'صفحة ${toArabicDigits(lastRead!.page)} من ٦٠٤'
                                    : 'تلاوة وقراءة وتدبر بدون إنترنت',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Primary Action
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.primaryLight.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.accentGold.withValues(alpha: 0.4)
                                  : AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                hasLastRead ? 'متابعة التلاوة' : 'ابدأ القراءة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 10,
                                color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Subtle Reading Progress Bar
                    if (hasLastRead) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? AppColors.accentGold : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// LEVEL 2: Compact Prayer Times Section (Real data, scannable strip)
  Widget _buildPrayerTimesSection({
    required BuildContext context,
    required PrayerLoaded state,
    required bool is24Hour,
    required bool isDark,
  }) {
    final prayers = state.prayerDay.prayerTimesOnly;
    final currentFocusType = state.prayerDay.focusPrayerType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'مواقيت الصلاة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              InkWell(
                onTap: () => _navigateToTab(2),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'عرض جميع المواقيت',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 11,
                        color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Scannable 5-prayer strip
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: prayers.map((p) {
              final isNext = p.type == currentFocusType;
              final timeFormatted = DateUtilsHelper.formatPrayerTime(
                p.time,
                is24Hour: is24Hour,
              );

              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isNext
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.35)
                            : AppColors.primaryContainer.withValues(alpha: 0.6))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isNext
                        ? Border.all(
                            color: isDark
                                ? AppColors.accentGold.withValues(alpha: 0.5)
                                : AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.type.nameArabic,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                          color: isNext
                              ? (isDark ? AppColors.accentGoldLight : AppColors.primary)
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeFormatted,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: isNext
                              ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                              : (isDark
                                  ? AppColors.textPrimaryDark.withValues(alpha: 0.8)
                                  : AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// LEVEL 3: Quick Adhkar Row (Lightweight quick actions, no large cards)
  Widget _buildQuickAzkarSection(bool isDark) {
    final quickItems = [
      {
        'title': 'أذكار الصباح',
        'cat': AzkarCategory.morning,
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'title': 'أذكار المساء',
        'cat': AzkarCategory.evening,
        'icon': Icons.nights_stay_outlined,
      },
      {
        'title': 'أذكار النوم',
        'cat': AzkarCategory.sleep,
        'icon': Icons.bedtime_outlined,
      },
      {
        'title': 'التسبيح',
        'cat': AzkarCategory.general,
        'icon': Icons.flare_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأذكار اليومية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              InkWell(
                onTap: () => _navigateToTab(3),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'عرض الكل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 11,
                        color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Lightweight quick action row
        Row(
          children: quickItems.map((item) {
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _navigateToAzkarCategory(item['cat'] as AzkarCategory),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder.withValues(alpha: 0.5)
                                : AppColors.lightBorder,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 20,
                          color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// LEVEL 3: Qibla Utility (Slim, compact utility, does not compete with hero)
  Widget _buildQiblaTile({
    required BuildContext context,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              FadeSlidePageRoute(page: const QiblaPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  Icons.explore_outlined,
                  size: 20,
                  color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'اتجاه القبلة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  بوصلة تحديد مسار الكعبة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// LEVEL 3: Daily Ayah Reflection (Calm, elegant surface near the bottom)
  Widget _buildDailyAyahSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard.withValues(alpha: 0.5)
            : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'آية اليوم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.accentGoldLight : AppColors.accentGold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'سورة الرعد • الآية ٢٨',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              final quranState = context.read<QuranBloc>().state;
              if (quranState is QuranLoaded) {
                final surahRad = quranState.allSurahs.firstWhere(
                  (s) => s.id == 13,
                  orElse: () => quranState.allSurahs.first,
                );
                Navigator.push(
                  context,
                  FadeSlidePageRoute(
                    page: SurahDetailPage(
                      surah: surahRad,
                      initialAyah: 28,
                    ),
                  ),
                );
              } else {
                _navigateToTab(1);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'فتح السورة في المصحف',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 10,
                    color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
