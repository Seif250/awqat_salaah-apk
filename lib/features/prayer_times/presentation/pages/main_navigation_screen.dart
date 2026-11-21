import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
  int _currentIndex = 0;
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
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
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
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
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
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: _isNavBarVisible
            ? Material(
                color: p.surface,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: p.hairline, width: 0.75),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      height: 62,
                      child: Row(
                        children: [
                          _buildNavItem(
                            index: 0,
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home_rounded,
                            label: 'الرئيسية',
                            palette: p,
                          ),
                          _buildNavItem(
                            index: 1,
                            icon: Icons.mosque_outlined,
                            selectedIcon: Icons.mosque_rounded,
                            label: 'المواقيت',
                            palette: p,
                          ),
                          _buildNavItem(
                            index: 2,
                            icon: Icons.auto_stories_outlined,
                            selectedIcon: Icons.auto_stories_rounded,
                            label: 'الأذكار',
                            palette: p,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required WirdPalette palette,
  }) {
    final isSelected = _currentIndex == index;
    final activeColor = palette.accentText;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '$label${isSelected ? '، الصفحة الحالية' : ''}',
        child: InkWell(
          onTap: () => navigateToPage(index),
          splashColor: palette.primary.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? palette.navActiveBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected ? activeColor : palette.textSecondary,
                    size: 21,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.badge(
                    isSelected ? activeColor : palette.textSecondary,
                    size: 11.5,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
