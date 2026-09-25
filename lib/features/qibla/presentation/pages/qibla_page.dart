import 'dart:async';
import 'dart:math';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../location/presentation/bloc/location_bloc.dart';
import '../../../location/presentation/bloc/location_event.dart';
import '../../../location/presentation/bloc/location_state.dart';
import '../../../location/presentation/widgets/location_picker_sheet.dart';
import '../../../prayer_times/presentation/bloc/prayer_bloc.dart';
import '../../../prayer_times/presentation/bloc/prayer_event.dart';
import '../../../prayer_times/presentation/bloc/prayer_state.dart';
import '../widgets/qibla_compass_widget.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _currentHeading = 0.0;
  bool _hasCompassSensor = true;
  bool _isAutoCompass = true;
  bool _sensorDataReceived = false;
  Timer? _sensorTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initCompass();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyLocationOnStartup();
    });
  }

  void _verifyLocationOnStartup() {
    if (!mounted) return;
    final locationState = context.read<LocationBloc>().state;
    if (locationState is! LocationSuccess || locationState.latitude == 0) {
      context.read<LocationBloc>().add(const RequestCurrentLocationEvent());
    }
  }

  @override
  void dispose() {
    _sensorTimeoutTimer?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  void _initCompass() {
    _sensorTimeoutTimer?.cancel();
    _compassSubscription?.cancel();

    final compassEvents = FlutterCompass.events;
    if (compassEvents == null) {
      if (mounted) {
        setState(() {
          _hasCompassSensor = false;
          _isAutoCompass = false;
        });
      }
      return;
    }

    // Timeout: if no sensor data arrives within 4 seconds, acknowledge sensor absence or delay
    _sensorTimeoutTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_sensorDataReceived) {
        setState(() {
          _hasCompassSensor = false;
          _isAutoCompass = false;
        });
      }
    });

    _compassSubscription = compassEvents.listen(
      (CompassEvent event) {
        final heading = event.heading;
        if (heading == null) return;
        if (!mounted) return;

        if (!_sensorDataReceived) {
          _sensorTimeoutTimer?.cancel();
          setState(() {
            _sensorDataReceived = true;
            _hasCompassSensor = true;
          });
        }

        if (_isAutoCompass) {
          final normalized = (heading % 360.0 + 360.0) % 360.0;
          setState(() {
            _currentHeading = normalized;
          });
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _hasCompassSensor = false;
          _isAutoCompass = false;
        });
      },
    );
  }

  void _resumeAutoCompass() {
    setState(() {
      _isAutoCompass = true;
    });
    if (!_sensorDataReceived) {
      _initCompass();
    }
  }

  // Holy Kaaba coordinates
  static const double kaabaLat = 21.422487;
  static const double kaabaLng = 39.826206;

  /// Great circle distance in kilometers using the Haversine formula
  double _calculateDistanceKm(double lat, double lng) {
    const earthRadiusKm = 6371.0;
    final dLat = (kaabaLat - lat) * (pi / 180.0);
    final dLon = (kaabaLng - lng) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * (pi / 180.0)) *
            cos(kaabaLat * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  String _getDirectionCardinal(double angle) {
    if (angle >= 337.5 || angle < 22.5) return 'شمال';
    if (angle >= 22.5 && angle < 67.5) return 'شمال شرق';
    if (angle >= 67.5 && angle < 112.5) return 'شرق';
    if (angle >= 112.5 && angle < 157.5) return 'جنوب شرق';
    if (angle >= 157.5 && angle < 202.5) return 'جنوب';
    if (angle >= 202.5 && angle < 247.5) return 'جنوب غرب';
    if (angle >= 247.5 && angle < 292.5) return 'غرب';
    return 'شمال غرب';
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.screen_rotation_rounded, color: AppColors.accentGold),
            SizedBox(width: 8),
            Text(
              'معايرة البوصلة',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.all_inclusive_rounded,
              size: 56,
              color: AppColors.accentGold,
            ),
            const SizedBox(height: 12),
            const Text(
              'للحصول على أعلى دقة، حرّك هاتفك في الهواء على شكل الرقم (8) بالإنجليزية عدة مرات بعيداً عن المعادن والمجالات المغناطيسية.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '💡 تأكد من تفعيل خدمة الموقع الجغرافي ووضع الهاتف في وضع أفقي مستوٍ.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentGold,
                  side: const BorderSide(color: AppColors.accentGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _initCompass();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('إعادة تهيئة البوصلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: const Color(0xFF1E1A17),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('حسناً، فهمت', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSunGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wb_sunny_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'تحديد القبلة بظل الشمس',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ظاهرة تعامد الشمس على الكعبة المشرفة:',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              'تتعامد الشمس مباشرة فوق الكعبة المشرفة مرتين كل عام (٢٧-٢٨ مايو و١٥-١٦ يوليو). في تلك اللحظات، يكون اتجاه القبلة في أي مكان في العالم معاكساً لظل أي شاخص عمودي.',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, height: 1.5),
            ),
            SizedBox(height: 10),
            Text(
              'وفي سائر الأيام، توفر البوصلة الرقمية والخريطة المدمجة التوجيه الدقيق المباشر.',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة الشريفة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wb_sunny_outlined),
            tooltip: 'تحديد القبلة بالشمس',
            onPressed: _showSunGuideDialog,
          ),
          IconButton(
            icon: const Icon(Icons.screen_rotation_outlined),
            tooltip: 'معايرة البوصلة',
            onPressed: _showCalibrationDialog,
          ),
        ],
      ),
      body: BlocBuilder<LocationBloc, LocationState>(
        builder: (context, locState) {
          double lat = 30.0444; // Default: Cairo
          double lng = 31.2357;
          String cityName = 'القاهرة';
          String countryName = 'مصر';

          if (locState is LocationSuccess) {
            lat = locState.latitude;
            lng = locState.longitude;
            cityName = locState.cityName;
            countryName = locState.countryName;
          } else {
            // Fallback to prayer bloc
            final prayerState = context.watch<PrayerBloc>().state;
            if (prayerState is PrayerLoaded) {
              cityName = prayerState.cityName;
              countryName = prayerState.countryName;
            }
          }

          // Calculate Qibla direction angle from True North using astronomical formula
          final qiblaObj = Qibla(Coordinates(lat, lng));
          final double qiblaAngle = qiblaObj.direction;
          final double distanceKm = _calculateDistanceKm(lat, lng);
          final cardinalDesc = _getDirectionCardinal(qiblaAngle);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top City Location Header with Change button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.accentGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$cityName، $countryName',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            Text(
                              '${lat.toStringAsFixed(2)}° ش • ${lng.toStringAsFixed(2)}° ق',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentGold,
                        ),
                        onPressed: () async {
                          await LocationPickerSheet.show(context);
                          if (context.mounted) {
                            context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                          }
                        },
                        icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                        label: const Text(
                          'تغيير',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Live Sensor Status Badge
                _buildSensorStatusBadge(isDark),

                // Qibla Compass Dial with Integrated Map Inside!
                Center(
                  child: QiblaCompassWidget(
                    userLat: lat,
                    userLng: lng,
                    qiblaAngle: qiblaAngle,
                    distanceKm: distanceKm,
                    currentHeading: _currentHeading,
                  ),
                ),
                const SizedBox(height: 24),

                // Live Angle Stats Grid (Bearing, Difference, Distance)
                Row(
                  children: [
                    _buildStatCard(
                      title: 'زاوية القبلة',
                      value: '${toArabicDigits(qiblaAngle.round())}°',
                      subtitle: cardinalDesc,
                      icon: Icons.explore_rounded,
                      color: AppColors.accentGold,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'المسافة لمكة',
                      value: toArabicDigits(distanceKm.round()),
                      subtitle: 'كيلومتر',
                      icon: Icons.straighten_rounded,
                      color: const Color(0xFF2E7D32),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _buildStatCard(
                      title: 'الاتجاه الحالي',
                      value: '${toArabicDigits(_currentHeading.round())}°',
                      subtitle: _getDirectionCardinal(_currentHeading),
                      icon: Icons.navigation_rounded,
                      color: const Color(0xFF1976D2),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Automatic Compass Sensor Status & Live Calibration Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.autorenew_rounded,
                              size: 20,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'التوجيه التلقائي للمستشعر نشط',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'تلقائي',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _hasCompassSensor
                                      ? 'البوصلة تدور تلقائياً مع حركة يدك لتوجيهك بدقة نحو القبلة'
                                      : 'جهازك لا يدعم مستشعر البوصلة المغناطيسي',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.screen_rotation_rounded, size: 20, color: AppColors.accentGold),
                            tooltip: 'معايرة البوصلة',
                            onPressed: _showCalibrationDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.4),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusBadge(bool isDark) {
    if (!_hasCompassSensor) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'مستشعر البوصلة المغناطيسي غير متوفر على هذا الجهاز. تم تفعيل التوجيه اليدوي بالسحب.',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    if (_isAutoCompass && _sensorDataReceived) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1B4D2E).withValues(alpha: isDark ? 0.4 : 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'البوصلة التلقائية نشطة • يلتف القرص تلقائياً مع دوران هاتفك',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              onPressed: () {
                setState(() {
                  _isAutoCompass = false;
                });
              },
              child: const Text('وضع يدوي', style: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: AppColors.accentGold)),
            ),
          ],
        ),
      );
    }

    if (!_isAutoCompass) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_rounded, color: Colors.orangeAccent, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'التوجيه اليدوي مفعل',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                foregroundColor: const Color(0xFF1E1A17),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _resumeAutoCompass,
              icon: const Icon(Icons.screen_rotation_rounded, size: 14),
              label: const Text(
                'تفعيل التلقائي',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // Still waiting for sensor response
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGold),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'جاري قراءة مستشعر البوصلة... حرّك الهاتف في الهواء لتنشيط المستشعر',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
