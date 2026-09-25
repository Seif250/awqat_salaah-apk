import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import 'qibla_map_radar_widget.dart';

class QiblaCompassWidget extends StatefulWidget {
  final double userLat;
  final double userLng;
  final double qiblaAngle; // True Qibla angle from North in degrees (0..360)
  final double distanceKm;
  final double currentHeading; // Current device heading in degrees (0..360)
  final ValueChanged<double>? onHeadingChanged;

  const QiblaCompassWidget({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.qiblaAngle,
    required this.distanceKm,
    required this.currentHeading,
    this.onHeadingChanged,
  });

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget> {
  double _continuousHeading = 0.0;
  bool _didVibrate = false;

  @override
  void initState() {
    super.initState();
    _continuousHeading = widget.currentHeading;
  }

  /// Difference between current device heading and Qibla angle
  double get _relativeAngle {
    double diff = widget.qiblaAngle - widget.currentHeading;
    while (diff < -180) {
      diff += 360;
    }
    while (diff > 180) {
      diff -= 360;
    }
    return diff;
  }

  bool get _isAligned => _relativeAngle.abs() <= 3.5;

  @override
  void didUpdateWidget(covariant QiblaCompassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentHeading != widget.currentHeading) {
      double diff = widget.currentHeading - (_continuousHeading % 360.0);
      while (diff < -180.0) {
        diff += 360.0;
      }
      while (diff > 180.0) {
        diff -= 360.0;
      }
      _continuousHeading += diff;
    }

    if (_isAligned && !_didVibrate) {
      HapticFeedback.heavyImpact();
      _didVibrate = true;
    } else if (!_isAligned) {
      _didVibrate = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double dialSize = 310.0;
    const double radarSize = 200.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live alignment indicator banner
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _isAligned
                ? const Color(0xFF1B4D2E)
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isAligned ? AppColors.accentGold : Colors.white12,
              width: _isAligned ? 1.5 : 1,
            ),
            boxShadow: _isAligned
                ? [
                    BoxShadow(
                      color: AppColors.accentGold.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isAligned
                    ? Icons.check_circle_rounded
                    : (_relativeAngle > 0
                        ? Icons.turn_right_rounded
                        : Icons.turn_left_rounded),
                color: _isAligned
                    ? AppColors.accentGoldLight
                    : (_relativeAngle.abs() <= 15
                        ? Colors.amberAccent
                        : Colors.white70),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isAligned
                    ? 'أنت بمواجهة الكعبة المشرفة مباشرة 🕋'
                    : (_relativeAngle > 0
                        ? 'أدر الهاتف يميناً بمقدار ${toArabicDigits(_relativeAngle.round())}°'
                        : 'أدر الهاتف يساراً بمقدار ${toArabicDigits(_relativeAngle.abs().round())}°'),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isAligned
                      ? Colors.white
                      : (_relativeAngle.abs() <= 15
                          ? Colors.amberAccent
                          : Colors.white70),
                ),
              ),
            ],
          ),
        ),

        // Interactive Compass Dial with Integrated Map Inside
        GestureDetector(
          onPanUpdate: (details) {
            // Allow manual rotation/testing of the compass
            final center = Offset(dialSize / 2, dialSize / 2);
            final touch = details.localPosition;
            final angle = (atan2(touch.dy - center.dy, touch.dx - center.dx) * 180 / pi + 90 + 360) % 360;
            widget.onHeadingChanged?.call(angle);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glowing halo when aligned
              if (_isAligned)
                Container(
                  width: dialSize + 16,
                  height: dialSize + 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

              // Rotating Dial Bezel
              AnimatedRotation(
                turns: -_continuousHeading / 360.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: dialSize,
                  height: dialSize,
                  child: CustomPaint(
                    painter: _CompassDialPainter(
                      qiblaAngle: widget.qiblaAngle,
                      isAligned: _isAligned,
                    ),
                  ),
                ),
              ),

              // Integrated Map Radar inside the central dial
              SizedBox(
                width: radarSize,
                height: radarSize,
                child: QiblaMapRadarWidget(
                  userLat: widget.userLat,
                  userLng: widget.userLng,
                  qiblaAngle: widget.qiblaAngle,
                  distanceKm: widget.distanceKm,
                  isAligned: _isAligned,
                  continuousHeading: _continuousHeading,
                ),
              ),

              // Needle pointer overlay pointing to Qibla
              AnimatedRotation(
                turns: (widget.qiblaAngle - _continuousHeading) / 360.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: dialSize,
                  height: dialSize,
                  child: CustomPaint(
                    painter: _QiblaPointerPainter(isAligned: _isAligned),
                  ),
                ),
              ),

              // Top North reference triangle (stationary relative to phone)
              Positioned(
                top: 2,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 28,
                  color: _isAligned ? AppColors.accentGold : Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final double qiblaAngle;
  final bool isAligned;

  _CompassDialPainter({
    required this.qiblaAngle,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer Bezel Ring
    final bezelPaint = Paint()
      ..color = const Color(0xFF14241B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bezelPaint);

    final borderPaint = Paint()
      ..color = isAligned ? AppColors.accentGold : const Color(0xFF4A6B56)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius - 1, borderPaint);

    // Inner rim dividing bezel from map
    final innerRimPaint = Paint()
      ..color = isAligned ? AppColors.accentGold : const Color(0xFF7A583A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius * 0.68, innerRimPaint);

    // 2. Degree ticks around dial
    for (int deg = 0; deg < 360; deg += 5) {
      final rad = (deg - 90) * (pi / 180.0);
      final isMajor = deg % 30 == 0;
      final isCardinal = deg % 90 == 0;

      final double tickLength = isCardinal ? 12.0 : (isMajor ? 8.0 : 4.0);
      final tickPaint = Paint()
        ..color = isCardinal
            ? (deg == 0 ? Colors.redAccent : Colors.white)
            : (isMajor ? AppColors.accentGold : Colors.white38)
        ..strokeWidth = isCardinal ? 2.0 : (isMajor ? 1.5 : 1.0);

      final p1 = Offset(
        center.dx + cos(rad) * (radius - 4),
        center.dy + sin(rad) * (radius - 4),
      );
      final p2 = Offset(
        center.dx + cos(rad) * (radius - 4 - tickLength),
        center.dy + sin(rad) * (radius - 4 - tickLength),
      );
      canvas.drawLine(p1, p2, tickPaint);

      // Degree Numbers
      if (isMajor && !isCardinal) {
        final textSpan = TextSpan(
          text: '$deg°',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 8,
            color: Colors.white60,
          ),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
        final textPos = Offset(
          center.dx + cos(rad) * (radius - 22) - tp.width / 2,
          center.dy + sin(rad) * (radius - 22) - tp.height / 2,
        );
        tp.paint(canvas, textPos);
      }
    }

    // 3. Arabic Cardinal Directions (ش N, ق E, ج S, غ W)
    final cardinals = [
      (label: 'ش', angle: 0.0, color: Colors.redAccent),
      (label: 'ق', angle: 90.0, color: Colors.white),
      (label: 'ج', angle: 180.0, color: Colors.white),
      (label: 'غ', angle: 270.0, color: Colors.white),
    ];

    for (final c in cardinals) {
      final rad = (c.angle - 90) * (pi / 180.0);
      final textSpan = TextSpan(
        text: c.label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: c.color,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.rtl)..layout();
      final textPos = Offset(
        center.dx + cos(rad) * (radius - 22) - tp.width / 2,
        center.dy + sin(rad) * (radius - 22) - tp.height / 2,
      );
      tp.paint(canvas, textPos);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.qiblaAngle != qiblaAngle || oldDelegate.isAligned != isAligned;
  }
}

class _QiblaPointerPainter extends CustomPainter {
  final bool isAligned;

  _QiblaPointerPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Needle pointing upwards towards Qibla
    final tip = Offset(center.dx, center.dy - radius + 14);
    final leftBase = Offset(center.dx - 9, center.dy - radius * 0.68 + 10);
    final rightBase = Offset(center.dx + 9, center.dy - radius * 0.68 + 10);

    final needlePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(rightBase.dx, rightBase.dy)
      ..lineTo(center.dx, center.dy - radius * 0.68 + 15)
      ..lineTo(leftBase.dx, leftBase.dy)
      ..close();

    final needlePaint = Paint()
      ..color = isAligned ? AppColors.accentGoldLight : AppColors.accentGold
      ..style = PaintingStyle.fill;
    canvas.drawPath(needlePath, needlePaint);

    final needleBorder = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(needlePath, needleBorder);

    // Kaaba emblem at the tip of the needle
    final emblemPaint = Paint()
      ..color = isAligned ? Colors.amberAccent : AppColors.accentGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, tip.dy - 3), 4.5, emblemPaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaPointerPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned;
  }
}
