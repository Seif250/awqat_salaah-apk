import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/prayer_constants.dart';

/// Restrained astronomical line-art glyph for each of the 6 daily prayer phases.
/// Drawn with uniform stroke weight for consistent clarity across light and dark modes.
class PrayerPhaseGlyph extends StatelessWidget {
  final PrayerType type;
  final Color color;
  final Color? accentColor;
  final double size;

  const PrayerPhaseGlyph({
    super.key,
    required this.type,
    required this.color,
    this.accentColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PrayerPhasePainter(
        type: type,
        color: color,
        accentColor: accentColor ?? color.withValues(alpha: 0.25),
      ),
    );
  }
}

class _PrayerPhasePainter extends CustomPainter {
  final PrayerType type;
  final Color color;
  final Color accentColor;

  _PrayerPhasePainter({
    required this.type,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (s * 0.082).clamp(1.3, 2.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillAccent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    switch (type) {
      case PrayerType.fajr:
        // Horizon + rising crescent glow + dawn star
        final horizonY = s * 0.72;
        canvas.drawLine(Offset(s * 0.14, horizonY), Offset(s * 0.86, horizonY), stroke);
        final arcRect = Rect.fromCircle(center: Offset(s * 0.5, horizonY), radius: s * 0.22);
        canvas.drawArc(arcRect, math.pi, math.pi, false, fillAccent);
        canvas.drawArc(arcRect, math.pi, math.pi, false, stroke);
        // Dawn star
        canvas.drawCircle(Offset(s * 0.5, s * 0.28), s * 0.055, Paint()..color = color);
        break;

      case PrayerType.sunrise:
        // Horizon + bright rising half sun with 3 short rays
        final horizonY = s * 0.70;
        canvas.drawLine(Offset(s * 0.14, horizonY), Offset(s * 0.86, horizonY), stroke);
        final sunRect = Rect.fromCircle(center: Offset(s * 0.5, horizonY), radius: s * 0.21);
        canvas.drawArc(sunRect, math.pi, math.pi, false, fillAccent);
        canvas.drawArc(sunRect, math.pi, math.pi, false, stroke);
        for (final angle in [-math.pi * 0.75, -math.pi * 0.5, -math.pi * 0.25]) {
          final p1 = Offset(s * 0.5 + math.cos(angle) * s * 0.30, horizonY + math.sin(angle) * s * 0.30);
          final p2 = Offset(s * 0.5 + math.cos(angle) * s * 0.40, horizonY + math.sin(angle) * s * 0.40);
          canvas.drawLine(p1, p2, stroke);
        }
        break;

      case PrayerType.dhuhr:
      case PrayerType.none:
        // Balanced high noon sun
        final center = Offset(s * 0.5, s * 0.5);
        canvas.drawCircle(center, s * 0.20, fillAccent);
        canvas.drawCircle(center, s * 0.20, stroke);
        for (int i = 0; i < 8; i++) {
          final angle = i * math.pi / 4;
          final p1 = Offset(center.dx + math.cos(angle) * s * 0.30, center.dy + math.sin(angle) * s * 0.30);
          final p2 = Offset(center.dx + math.cos(angle) * s * 0.40, center.dy + math.sin(angle) * s * 0.40);
          canvas.drawLine(p1, p2, stroke);
        }
        break;

      case PrayerType.asr:
        // Afternoon sun lowered toward horizon with shadow angle
        final sunCenter = Offset(s * 0.46, s * 0.46);
        canvas.drawCircle(sunCenter, s * 0.18, fillAccent);
        canvas.drawCircle(sunCenter, s * 0.18, stroke);
        canvas.drawLine(Offset(s * 0.16, s * 0.78), Offset(s * 0.84, s * 0.78), stroke);
        canvas.drawLine(Offset(s * 0.46, s * 0.15), Offset(s * 0.46, s * 0.21), stroke);
        canvas.drawLine(Offset(s * 0.16, s * 0.46), Offset(s * 0.21, s * 0.46), stroke);
        canvas.drawLine(Offset(s * 0.25, s * 0.25), Offset(s * 0.29, s * 0.29), stroke);
        break;

      case PrayerType.maghrib:
        // Setting horizon + crescent sliver above
        final horizonY = s * 0.72;
        canvas.drawLine(Offset(s * 0.14, horizonY), Offset(s * 0.86, horizonY), stroke);
        final duskRect = Rect.fromCircle(center: Offset(s * 0.5, horizonY), radius: s * 0.19);
        canvas.drawArc(duskRect, math.pi, math.pi, false, fillAccent);
        canvas.drawArc(duskRect, math.pi, math.pi, false, stroke);
        // Subtle evening star off-center
        canvas.drawCircle(Offset(s * 0.74, s * 0.30), s * 0.048, Paint()..color = color);
        break;

      case PrayerType.isha:
        // Clean night crescent + single quiet star
        final crescent = Path()
          ..addArc(
            Rect.fromCircle(center: Offset(s * 0.46, s * 0.52), radius: s * 0.28),
            math.pi * 0.35,
            math.pi * 1.45,
          );
        canvas.drawPath(crescent, stroke);
        canvas.drawCircle(Offset(s * 0.70, s * 0.30), s * 0.052, Paint()..color = color);
        canvas.drawCircle(Offset(s * 0.76, s * 0.52), s * 0.036, Paint()..color = color.withValues(alpha: 0.7));
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _PrayerPhasePainter old) =>
      old.type != type || old.color != color || old.accentColor != accentColor;
}

/// Subtle hairline architectural arch used lightly on the splash screen.
class WirdArchPainter extends CustomPainter {
  final Color strokeColor;
  final double progress;

  const WirdArchPainter({
    required this.strokeColor,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final archPath = Path()
      ..moveTo(w * 0.14, h * 0.92)
      ..lineTo(w * 0.14, h * 0.44)
      ..cubicTo(
        w * 0.14,
        h * 0.20,
        w * 0.34,
        h * 0.10,
        w * 0.50,
        h * 0.04,
      )
      ..cubicTo(
        w * 0.66,
        h * 0.10,
        w * 0.86,
        h * 0.20,
        w * 0.86,
        h * 0.44,
      )
      ..lineTo(w * 0.86, h * 0.92);

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    if (progress >= 0.99) {
      canvas.drawPath(archPath, paint);
    } else {
      for (final metric in archPath.computeMetrics()) {
        final extract = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));
        canvas.drawPath(extract, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WirdArchPainter old) =>
      old.strokeColor != strokeColor || old.progress != progress;
}
