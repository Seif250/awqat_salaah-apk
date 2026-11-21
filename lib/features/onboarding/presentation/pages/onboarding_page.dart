import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final p = context.palette;

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
      backgroundColor: p.background,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mosque_outlined,
                            size: 20, color: p.accentText),
                        const SizedBox(width: 8),
                        Text(
                          'وِرد',
                          style: AppTypography.pageTitle(p.textPrimary)
                              .copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                    if (_currentPage < 2)
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            2,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: Text(
                          'تخطي',
                          style: AppTypography.label(p.accentText, size: 13.5),
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
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 28),
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: p.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                slide.icon,
                                size: 48,
                                color: p.accentText,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: p.cardElevated,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              slide.badge,
                              style: AppTypography.badge(
                                p.accentText,
                                size: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: AppTypography.pageTitle(p.textPrimary)
                                .copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: AppTypography.body(
                              p.textSecondary,
                              size: 15,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Area: Indicators & Action Buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? p.primary
                                : p.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_currentPage < 2)
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.primary,
                          foregroundColor: p.onPrimary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'التالي',
                              style: AppTypography.label(p.onPrimary, size: 15.5),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded,
                                color: p.onPrimary, size: 20),
                          ],
                        ),
                      )
                    else ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<LocationBloc>()
                              .add(const RequestCurrentLocationEvent());
                        },
                        icon: Icon(Icons.my_location_rounded,
                            color: p.onPrimary),
                        label: Text(
                          'استخدام الموقع الحالي (تلقائي)',
                          style: AppTypography.label(p.onPrimary, size: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.primary,
                          foregroundColor: p.onPrimary,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                        icon: Icon(Icons.location_city_outlined,
                            color: p.accentText),
                        label: Text(
                          'اختيار المدينة يدوياً',
                          style: AppTypography.label(p.accentText, size: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          side: BorderSide(color: p.border, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
