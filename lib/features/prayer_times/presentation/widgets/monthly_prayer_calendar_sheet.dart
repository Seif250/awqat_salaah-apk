import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../data/models/prayer_day_model.dart';
import '../bloc/prayer_bloc.dart';

class MonthlyPrayerCalendarSheet extends StatefulWidget {
  final String cityName;
  final String countryName;
  final bool is24Hour;

  const MonthlyPrayerCalendarSheet({
    super.key,
    required this.cityName,
    required this.countryName,
    required this.is24Hour,
  });

  static Future<void> show(
    BuildContext context, {
    required String cityName,
    required String countryName,
    required bool is24Hour,
  }) {
    final prayerBloc = context.read<PrayerBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider<PrayerBloc>.value(
        value: prayerBloc,
        child: MonthlyPrayerCalendarSheet(
          cityName: cityName,
          countryName: countryName,
          is24Hour: is24Hour,
        ),
      ),
    );
  }

  @override
  State<MonthlyPrayerCalendarSheet> createState() =>
      _MonthlyPrayerCalendarSheetState();
}

class _MonthlyPrayerCalendarSheetState
    extends State<MonthlyPrayerCalendarSheet> {
  late int _year;
  late int _month;
  late List<PrayerDayModel> _days;
  late final ScrollController _scrollController;

  static const List<String> _gregorianMonths = [
    '',
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const List<String> _hijriMonths = [
    '',
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الثانية',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static const List<String> _shortWeekdays = [
    '',
    'إث',
    'ثل',
    'أر',
    'خم',
    'جم',
    'سب',
    'أح',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _scrollController = ScrollController();
    _loadMonth();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMonth() {
    _days = context.read<PrayerBloc>().calculateMonthPrayers(_year, _month);
  }

  void _changeMonth(int delta) {
    final next = DateTime(_year, _month + delta, 1);
    setState(() {
      _year = next.year;
      _month = next.month;
      _loadMonth();
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  void _scrollToToday() {
    if (!mounted || !_scrollController.hasClients) return;
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) {
      final offset = ((now.day - 3).clamp(0, _days.length - 1)) * 46.0;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _hijriSpanLabel() {
    if (_days.isEmpty) return '';
    final first = HijriCalendar.fromDate(_days.first.date);
    final last = HijriCalendar.fromDate(_days.last.date);
    final m1 = (first.hMonth >= 1 && first.hMonth <= 12)
        ? _hijriMonths[first.hMonth]
        : '';
    final m2 = (last.hMonth >= 1 && last.hMonth <= 12)
        ? _hijriMonths[last.hMonth]
        : '';
    if (first.hMonth == last.hMonth) {
      return '$m1 ${toArabicDigits(first.hYear)} هـ';
    }
    return '$m1 - $m2 ${toArabicDigits(last.hYear)} هـ';
  }

  String _compactTime(DateTime dt) {
    if (widget.is24Hour) {
      return DateUtilsHelper.formatPrayerTime(dt, is24Hour: true);
    }
    final rawHour = dt.hour % 12;
    final hour = (rawHour == 0 ? 12 : rawHour).toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;
    final now = DateTime.now();
    final locationLabel = widget.countryName.isNotEmpty
        ? '${widget.cityName}، ${widget.countryName}'
        : widget.cityName;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: p.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Top Header: Title + City + Close
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: p.accentText,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'التقويم الشهري لمواقيت الصلاة',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        locationLabel,
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 12,
                          color: p.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Open Month Switcher Bar (no heavy double border)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'الشهر السابق',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _changeMonth(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${_gregorianMonths[_month]} ${toArabicDigits(_year)}',
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      Text(
                        _hijriSpanLabel(),
                        style: TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: p.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'الشهر التالي',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),

          // Sticky Column Header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: p.primary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _HeaderCell('اليوم')),
                Expanded(flex: 2, child: _HeaderCell('الفجر')),
                Expanded(flex: 2, child: _HeaderCell('الظهر')),
                Expanded(flex: 2, child: _HeaderCell('العصر')),
                Expanded(flex: 2, child: _HeaderCell('المغرب')),
                Expanded(flex: 2, child: _HeaderCell('العشاء')),
              ],
            ),
          ),

          // Scrollable Month Rows
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: p.background,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border.all(
                  color: p.hairline,
                  width: 0.75,
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: _days.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.65,
                    color: p.hairline.withValues(alpha: 0.65),
                  ),
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isToday = day.date.year == now.year &&
                        day.date.month == now.month &&
                        day.date.day == now.day;
                    final isFriday = day.date.weekday == DateTime.friday;
                    final weekdayLabel = _shortWeekdays[day.date.weekday];

                    return Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isToday
                            ? p.cardElevated
                            : (isFriday
                                ? p.primaryContainer.withValues(alpha: 0.35)
                                : Colors.transparent),
                        border: isToday
                            ? Border(
                                right: BorderSide(
                                  color: p.accent,
                                  width: 3,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  toArabicDigits(day.date.day),
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    fontSize: 12,
                                    fontWeight: isToday || isFriday
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isToday || isFriday
                                        ? p.accentText
                                        : p.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  weekdayLabel,
                                  style: TextStyle(
                                    fontFamily: 'IBMPlexSansArabic',
                                    fontSize: 10,
                                    fontWeight: isFriday
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isFriday
                                        ? p.accentText
                                        : p.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TimeCell(_compactTime(day.fajr.time),
                                isToday: isToday, isDark: isDark),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TimeCell(_compactTime(day.dhuhr.time),
                                isToday: isToday, isDark: isDark),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TimeCell(_compactTime(day.asr.time),
                                isToday: isToday, isDark: isDark),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TimeCell(_compactTime(day.maghrib.time),
                                isToday: isToday, isDark: isDark),
                          ),
                          Expanded(
                            flex: 2,
                            child: _TimeCell(_compactTime(day.isha.time),
                                isToday: isToday, isDark: isDark),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.label(Colors.white, weight: FontWeight.w700),
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final String text;
  final bool isToday;
  final bool isDark;

  const _TimeCell(
    this.text, {
    required this.isToday,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTypography.label(
          isToday ? p.accentText : p.textPrimary,
          weight: isToday ? FontWeight.w800 : FontWeight.w600,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}
