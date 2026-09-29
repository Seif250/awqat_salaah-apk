import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1500));
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 1.15,
            colors: isDark
                ? [
                    const Color(0xFF263B32),
                    const Color(0xFF101914),
                  ]
              : [
                    const Color(0xFFFFFCF4),
                    const Color(0xFFF0E7D4),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 19,
                  color: AppColors.accentGold.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 42),
              // Animated Logo emblem
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Container(
                        width: 114,
                        height: 114,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? const Color(0xFF2EC486)
                                      : AppColors.primary)
                                  .withValues(alpha: isDark ? 0.35 : 0.2),
                              blurRadius: 28,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 114,
                            height: 114,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 26),

              // Animated App Title & Ayah with brand green typography
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        'وِرد',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFF2EC486)
                              : AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'صلاتك، قرآنك، ذكرك',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF8FD8B4)
                              : AppColors.primaryLight,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Quiet loading indicator in brand green
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? const Color(0xFF2EC486)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'نُهَيِّئ لك وردك',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFA5C4B4)
                            : AppColors.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
