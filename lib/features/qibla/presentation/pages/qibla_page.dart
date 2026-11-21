import 'dart:async';
import 'dart:math';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.screen_rotation_rounded, color: p.accentText),
            const SizedBox(width: 8),
            Text('معايرة البوصلة', style: AppTypography.sectionHeader(p.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.all_inclusive_rounded,
              size: 56,
              color: p.accentText,
            ),
            const SizedBox(height: 12),
            Text(
              'للحصول على أعلى دقة، حرّك هاتفك في الهواء على شكل الرقم (8) بالإنجليزية عدة مرات بعيداً عن المعادن والمجالات المغناطيسية.',
              textAlign: TextAlign.center,
              style: AppTypography.body(p.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: p.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '💡 تأكد من تفعيل خدمة الموقع الجغرافي ووضع الهاتف في وضع أفقي مستوٍ.',
                textAlign: TextAlign.center,
                style: AppTypography.label(p.textPrimary),
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
                  foregroundColor: p.accentText,
                  side: BorderSide(color: p.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _initCompass();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  'إعادة تهيئة البوصلة',
                  style: AppTypography.meta(p.accentText, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: p.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'حسناً، فهمت',
                  style: AppTypography.meta(p.onPrimary, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: AppTypography.pageTitle(p.textPrimary),
        ),
        actions: [
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
            final prayerState = context.watch<PrayerBloc>().state;
            if (prayerState is PrayerLoaded) {
              cityName = prayerState.cityName;
              countryName = prayerState.countryName;
            }
          }

          final qiblaObj = Qibla(Coordinates(lat, lng));
          final double qiblaAngle = qiblaObj.direction;
          final double distanceKm = _calculateDistanceKm(lat, lng);
          final cardinalDesc = _getDirectionCardinal(qiblaAngle);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clean Location Selector Row (city & country only, no raw coordinates)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: p.accentText,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$cityName، $countryName',
                          style: AppTypography.rowTitle(p.textPrimary),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: p.accentText,
                        ),
                        onPressed: () async {
                          await LocationPickerSheet.show(context);
                          if (context.mounted) {
                            context.read<PrayerBloc>().add(const RefreshPrayerTimesEvent());
                          }
                        },
                        icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                        label: Text(
                          'تغيير',
                          style: AppTypography.meta(p.accentText, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 0.75, color: p.hairline),
                const SizedBox(height: 16),

                // Show compact status strip only when needed (sensor missing / loading / manual)
                _buildSensorStatusBadge(p),

                // Qibla Compass Dial with Integrated Radar Inside
                Center(
                  child: QiblaCompassWidget(
                    userLat: lat,
                    userLng: lng,
                    qiblaAngle: qiblaAngle,
                    distanceKm: distanceKm,
                    currentHeading: _currentHeading,
                    onHeadingChanged: (angle) {
                      setState(() {
                        _isAutoCompass = false;
                        _currentHeading = angle;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Concise 2-Column Metrics Strip divided by a clean vertical hairline
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: p.hairline, width: 0.75),
                      bottom: BorderSide(color: p.hairline, width: 0.75),
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _buildStatColumn(
                          p: p,
                          title: 'زاوية القبلة',
                          value: '${toArabicDigits(qiblaAngle.round())}°',
                          subtitle: cardinalDesc,
                          accentColor: p.accentText,
                        ),
                        Container(width: 0.75, color: p.hairline),
                        _buildStatColumn(
                          p: p,
                          title: 'المسافة لمكة',
                          value: '${toArabicDigits(distanceKm.round())} كم',
                          subtitle: 'المسجد الحرام',
                          accentColor: p.accentText,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn({
    required WirdPalette p,
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Text(title, style: AppTypography.label(p.textSecondary)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.sectionHeader(p.textPrimary).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.badge(accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusBadge(WirdPalette p) {
    if (!_hasCompassSensor) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: p.cardElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: p.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'مستشعر البوصلة المغناطيسي غير متوفر على هذا الجهاز. تم تفعيل التوجيه اليدوي بالسحب.',
                style: AppTypography.label(p.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    if (_isAutoCompass && _sensorDataReceived) {
      return const SizedBox.shrink();
    }

    if (!_isAutoCompass) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: p.cardElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, color: p.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'التوجيه اليدوي مفعل',
                style: AppTypography.label(p.textPrimary, weight: FontWeight.w700),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
                elevation: 0,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _resumeAutoCompass,
              icon: const Icon(Icons.screen_rotation_rounded, size: 14),
              label: Text(
                'تفعيل التلقائي',
                style: AppTypography.badge(p.onPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: p.cardElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: p.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'جاري قراءة مستشعر البوصلة... حرّك الهاتف في الهواء لتنشيط المستشعر',
              style: AppTypography.label(p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
