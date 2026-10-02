import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../azkar/presentation/pages/azkar_page.dart';
import 'home_page.dart';
import 'prayer_times_page.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static MainNavigationScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationScreenState>();
  }

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late final PageController _pageController;
  int _currentIndex = 0; // Default to HomePage (الرئيسية) as specified
  bool _isNavBarVisible = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void navigateToPage(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
      _isNavBarVisible = true;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void showNavBar() {
    if (!_isNavBarVisible) {
      setState(() => _isNavBarVisible = true);
    }
  }

  void hideNavBar() {
    if (_isNavBarVisible) {
      setState(() => _isNavBarVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_isNavBarVisible) {
                setState(() => _isNavBarVisible = false);
              }
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isNavBarVisible) {
                setState(() => _isNavBarVisible = true);
              }
            }
          }
          return false;
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
              _isNavBarVisible = true;
            });
          },
          children: const [
            HomePage(),
            PrayerTimesPage(),
            AzkarPage(),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1.2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isNavBarVisible ? 1.0 : 0.0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.wirdWhite,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.wirdBorder,
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 74,
                child: Row(
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: 'الرئيسية',
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.mosque_outlined,
                      selectedIcon: Icons.mosque_rounded,
                      label: 'المواقيت',
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.format_list_bulleted_rounded,
                      selectedIcon: Icons.format_list_bulleted_rounded,
                      label: 'الأذكار',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label${isSelected ? '، الصفحة الحالية' : ''}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => navigateToPage(index),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 56,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF1B4D3E)
                              : AppColors.wirdSageGreen)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        isSelected ? selectedIcon : icon,
                        color: isSelected
                            ? (isDark ? AppColors.accentGoldLight : AppColors.wirdPrimaryGreen)
                            : (isDark ? Colors.white60 : const Color(0xFF7B8581)),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 10.5,
                      color: isSelected
                          ? (isDark ? AppColors.accentGoldLight : AppColors.wirdPrimaryGreen)
                          : (isDark ? Colors.white60 : const Color(0xFF7B8581)),
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
