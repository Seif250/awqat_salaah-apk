import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_color_palette.dart';
import '../../../../core/theme/app_typography.dart';
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
    final screenW = MediaQuery.of(context).size.width;
    final double dialSize = (screenW - 56).clamp(240.0, 296.0);
    final double radarSize = dialSize * 0.64;
    final p = context.palette;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live alignment indicator banner (calm, high-contrast)
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: _isAligned ? p.primary : p.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isAligned ? p.accent : p.hairline,
              width: _isAligned ? 1.5 : 0.75,
            ),
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
                color: _isAligned ? p.accentLight : p.accentText,
                size: 19,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isAligned
                      ? 'أنت بمواجهة القبلة مباشرة'
                      : (_relativeAngle > 0
                          ? 'أدر الهاتف يميناً ${toArabicDigits(_relativeAngle.round())}°'
                          : 'أدر الهاتف يساراً ${toArabicDigits(_relativeAngle.abs().round())}°'),
                  style: AppTypography.meta(
                    _isAligned ? p.onPrimary : p.accentText,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Interactive Compass Dial with Integrated Radar Inside
        GestureDetector(
          onPanUpdate: (details) {
            final center = Offset(dialSize / 2, dialSize / 2);
            final touch = details.localPosition;
            final angle = (atan2(touch.dy - center.dy, touch.dx - center.dx) * 180 / pi + 90 + 360) % 360;
            widget.onHeadingChanged?.call(angle);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer subtle halo when aligned
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: dialSize + 14,
                height: dialSize + 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: _isAligned
                      ? [
                          BoxShadow(
                            color: p.primary.withValues(alpha: 0.24),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: p.isDark ? 0.25 : 0.06),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
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
                      isDark: p.isDark,
                      surfaceColor: p.surface,
                      borderColor: p.border,
                      primaryColor: p.primary,
                      accentColor: p.accent,
                      textColor: p.textPrimary,
                      mutedColor: p.textSecondary,
                      northColor: p.error,
                    ),
                  ),
                ),
              ),

              // Integrated Radar Inside the Central Dial
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
                    painter: _QiblaPointerPainter(
                      isAligned: _isAligned,
                      primaryColor: p.primary,
                      accentColor: p.accent,
                      accentLightColor: p.accentLight,
                    ),
                  ),
                ),
              ),

              // Top reference marker (stationary relative to phone)
              Positioned(
                top: 2,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 28,
                  color: _isAligned ? p.accent : p.primary,
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
  final bool isDark;
  final Color surfaceColor;
  final Color borderColor;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final Color northColor;

  _CompassDialPainter({
    required this.qiblaAngle,
    required this.isAligned,
    required this.isDark,
    required this.surfaceColor,
    required this.borderColor,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.northColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Clean Dial Face matched to app palette
    final bezelPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bezelPaint);

    final borderPaint = Paint()
      ..color = isAligned ? primaryColor : borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAligned ? 2.5 : 1.5;
    canvas.drawCircle(center, radius - 1.5, borderPaint);

    // Inner hairline dividing bezel from center radar
    final innerRimPaint = Paint()
      ..color = isAligned ? accentColor : borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.65, innerRimPaint);

    // 2. Clean Degree Ticks
    for (int deg = 0; deg < 360; deg += 5) {
      final rad = (deg - 90) * (pi / 180.0);
      final isMajor = deg % 30 == 0;
      final isCardinal = deg % 90 == 0;

      final double tickLength = isCardinal ? 11.0 : (isMajor ? 7.0 : 3.5);
      final tickPaint = Paint()
        ..color = isCardinal
            ? (deg == 0 ? northColor : textColor)
            : (isMajor
                ? primaryColor.withValues(alpha: 0.7)
                : mutedColor.withValues(alpha: 0.35))
        ..strokeWidth = isCardinal ? 2.0 : (isMajor ? 1.4 : 0.9);

      final p1 = Offset(
        center.dx + cos(rad) * (radius - 4),
        center.dy + sin(rad) * (radius - 4),
      );
      final p2 = Offset(
        center.dx + cos(rad) * (radius - 4 - tickLength),
        center.dy + sin(rad) * (radius - 4 - tickLength),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 3. Arabic Cardinal Directions (ش N, ق E, ج S, غ W)
    final cardinals = [
      (label: 'ش', angle: 0.0, color: northColor),
      (label: 'ق', angle: 90.0, color: textColor),
      (label: 'ج', angle: 180.0, color: textColor),
      (label: 'غ', angle: 270.0, color: textColor),
    ];

    for (final c in cardinals) {
      final rad = (c.angle - 90) * (pi / 180.0);
      final textSpan = TextSpan(
        text: c.label,
        style: TextStyle(
          fontFamily: AppTypography.uiFont,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: c.color,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.rtl)..layout();
      final textPos = Offset(
        center.dx + cos(rad) * (radius - 26) - tp.width / 2,
        center.dy + sin(rad) * (radius - 26) - tp.height / 2,
      );
      tp.paint(canvas, textPos);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.isDark != isDark ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.primaryColor != primaryColor;
  }
}

class _QiblaPointerPainter extends CustomPainter {
  final bool isAligned;
  final Color primaryColor;
  final Color accentColor;
  final Color accentLightColor;

  _QiblaPointerPainter({
    required this.isAligned,
    required this.primaryColor,
    required this.accentColor,
    required this.accentLightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tip = Offset(center.dx, center.dy - radius + 14);
    final leftBase = Offset(center.dx - 8.5, center.dy - radius * 0.65 + 8);
    final rightBase = Offset(center.dx + 8.5, center.dy - radius * 0.65 + 8);

    final needlePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(rightBase.dx, rightBase.dy)
      ..lineTo(center.dx, center.dy - radius * 0.65 + 14)
      ..lineTo(leftBase.dx, leftBase.dy)
      ..close();

    final needlePaint = Paint()
      ..color = isAligned ? primaryColor : accentColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(needlePath, needlePaint);

    final emblemPaint = Paint()
      ..color = isAligned ? accentColor : primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, tip.dy - 2), 4.5, emblemPaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaPointerPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
