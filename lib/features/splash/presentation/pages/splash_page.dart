import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/prayer_phase_glyph.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../../../services/storage_service.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../prayer_times/presentation/pages/main_navigation_screen.dart';

class SplashPage extends StatefulWidget {
  final StorageService storageService;

  const SplashPage({super.key, required this.storageService});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();

    // Navigate immediately once the first frame is laid out (no artificial delay).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToNext();
    });
  }

  void _navigateToNext() {
    if (!mounted) return;
    final targetPage = widget.storageService.isFirstLaunch
        ? OnboardingPage(storageService: widget.storageService)
        : const MainNavigationScreen();

    Navigator.of(context).pushReplacement(
      FadeSlidePageRoute(page: targetPage),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 148,
                    height: 164,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WirdArchPainter(
                              strokeColor: p.primary.withValues(
                                alpha: p.isDark ? 0.35 : 0.20,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 76,
                              height: 76,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppConstants.appName,
                    style: AppTypography.heroTitle(p.textPrimary).copyWith(
                      fontSize: 34,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.appSubtitle,
                    style: AppTypography.body(
                      p.textSecondary,
                      size: 15,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
