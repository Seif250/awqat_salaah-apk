import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../services/storage_service.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../../../prayer_times/presentation/pages/main_navigation_screen.dart';

class OnboardingPage extends StatefulWidget {
  final StorageService storageService;

  const OnboardingPage({super.key, required this.storageService});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToHome(BuildContext context) async {
    await widget.storageService.setFirstLaunchCompleted();
    if (context.mounted) {
      context.read<PrayerBloc>().add(const LoadPrayerTimesEvent());
      Navigator.of(context).pushReplacement(
        FadeSlidePageRoute(page: const MainNavigationScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final slides = [
      _OnboardingSlideData(
        icon: Icons.access_time_filled_rounded,
        title: 'مواقيت دقيقة لكل صلاة',
        description:
            'حساب فلكي دقيق وفق الهيئة المصرية أو أم القرى، مع عداد تنازلي ذكي للصلاة القادمة وتنبيهات أذان وإقامة.',
        badge: 'دقة حسابية عالية',
      ),
      _OnboardingSlideData(
        icon: Icons.menu_book_rounded,
        title: 'أذكارك ووردك اليومي',
        description:
            'أذكار الصباح والمساء، أذكار النوم، مع سبحة إلكترونية تفاعلية وتتبع نسبة إنجاز وردك طوال اليوم.',
        badge: 'حصن المسلم وتتبع الورد',
      ),
      _OnboardingSlideData(
        icon: Icons.widgets_rounded,
        title: 'ودجت الشاشة وبدون إنترنت',
        description:
            'ودجت أنيقة للشاشة الرئيسية تعرض مواعيد الصلوات والوقت المتبقي، ويعمل التطبيق بدون أي اتصال بالإنترنت.',
        badge: 'يعمل Offline-First',
      ),
    ];

    return Scaffold(
      body: BlocListener<LocationBloc, LocationState>(
        listener: (context, state) {
          if (state is LocationSuccess) {
            _navigateToHome(context);
          } else if (state is LocationPermissionDeniedState) {
            AppSnackBar.showWarning(context, state.message);
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Skip Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand mark
                    Row(
                      children: [
                        const Icon(Icons.mosque_rounded, size: 22, color: AppColors.accentGold),
                        const SizedBox(width: 8),
                        Text(
                          'وِرد',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    if (_currentPage < 2)
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            2,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: const Text(
                          'تخطي',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          // Icon Container with layered glow
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accentGold.withValues(alpha: 0.6),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accentGold.withValues(alpha: isDark ? 0.2 : 0.1),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                slide.icon,
                                size: 58,
                                color: AppColors.accentGold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              slide.badge,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Title
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Description
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              height: 1.6,
                              fontSize: 14.5,
                            ),
                          ),
                          const Spacer(flex: 2),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Area: Indicators & Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  children: [
                    // Dot Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppColors.accentGold
                                : (isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation buttons
                    if (_currentPage < 2)
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'التالي',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      )
                    else ...[
                      // Final Slide: Location selection
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<LocationBloc>()
                              .add(const RequestCurrentLocationEvent());
                        },
                        icon: const Icon(Icons.my_location_rounded, color: Colors.white),
                        label: const Text(
                          'استخدام الموقع الحالي (تلقائي)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await LocationPickerSheet.show(context);
                          if (context.mounted) {
                            _navigateToHome(context);
                          }
                        },
                        icon: const Icon(Icons.location_city_rounded, color: AppColors.accentGold),
                        label: const Text(
                          'اختيار المدينة يدوياً',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: const BorderSide(color: AppColors.accentGold, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String description;
  final String badge;

  _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
  });
}
