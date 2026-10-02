import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_system.dart';
import '../../../../core/utils/date_utils.dart';

class HeaderWidget extends StatefulWidget {
  final String cityName;
  final String countryName;
  final VoidCallback onLocationTap;

  const HeaderWidget({
    super.key,
    required this.cityName,
    required this.countryName,
    required this.onLocationTap,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget>
    with WidgetsBindingObserver {
  late String _gregorianDate;
  late String _hijriDate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateDateStrings();
    _startTimer();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background — stop timer to save battery
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // App coming back — restart timer and update dates immediately
      _startTimer();
      _updateDateStrings();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateDateStrings();
    });
  }

  void _updateDateStrings() {
    final now = DateTime.now();
    final gregorianDate =
        DateUtilsHelper.getGregorianDateFormatted(now, locale: 'ar');
    final hijriDate =
        DateUtilsHelper.getHijriDateFormatted(now, locale: 'ar');
    if (mounted) {
      setState(() {
        _gregorianDate = gregorianDate;
        _hijriDate = hijriDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationDisplay = widget.cityName.isNotEmpty &&
            widget.countryName.isNotEmpty
        ? '${widget.cityName}، ${widget.countryName}'
        : 'موقعي الحالي، مصر';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Right (RTL start): City Selector Pill
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onLocationTap,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : Colors.white,
                  borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusPill),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFEFF2F0),
                    width: 0.9,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: 135),
                      child: Text(
                        locationDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF163A29),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Left (RTL end): Hijri and Gregorian Dates
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hijriDate,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.accentGoldLight
                        : const Color(0xFF8C5D00),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _gregorianDate,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white60
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}