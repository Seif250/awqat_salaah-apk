import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
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
    final p = context.palette;
    final locationDisplay =
        widget.cityName.isNotEmpty && widget.countryName.isNotEmpty
            ? '${widget.cityName}، ${widget.countryName}'
            : 'موقعي الحالي، مصر';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 6,
        spacing: 12,
        children: [
          // Open Interactive City Selector (no clunky pill box)
          InkWell(
            onTap: widget.onLocationTap,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: p.accentText,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        locationDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.rowTitle(
                          p.textPrimary,
                          weight: FontWeight.w700,
                        ).copyWith(fontSize: 13.5),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: p.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Hijri + Gregorian Dates
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _hijriDate,
                style: AppTypography.label(p.accentText, size: 13),
              ),
              Text(
                _gregorianDate,
                style: AppTypography.meta(p.textSecondary, size: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
