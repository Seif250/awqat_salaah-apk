import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_color_palette.dart';

class QiblaMapRadarWidget extends StatefulWidget {
  final double userLat;
  final double userLng;
  final double qiblaAngle;
  final double distanceKm;
  final bool isAligned;
  final double compassRotation; // In radians
  final double continuousHeading; // In degrees

  const QiblaMapRadarWidget({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.qiblaAngle,
    required this.distanceKm,
    this.isAligned = false,
    this.compassRotation = 0.0,
    this.continuousHeading = 0.0,
  });

  @override
  State<QiblaMapRadarWidget> createState() => _QiblaMapRadarWidgetState();
}

class _QiblaMapRadarWidgetState extends State<QiblaMapRadarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return ClipOval(
          child: Container(
            color: p.primaryContainer,
            child: AnimatedRotation(
              turns: -widget.continuousHeading / 360.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: CustomPaint(
                painter: _RadarMapPainter(
                  userLat: widget.userLat,
                  userLng: widget.userLng,
                  qiblaAngle: widget.qiblaAngle,
                  pulseProgress: _animController.value,
                  isAligned: widget.isAligned,
                  primaryColor: p.primary,
                  accentColor: p.accent,
                  accentLightColor: p.accentLight,
                  textColor: p.textPrimary,
                  borderColor: p.border,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RadarMapPainter extends CustomPainter {
  final double userLat;
  final double userLng;
  final double qiblaAngle;
  final double pulseProgress;
  final bool isAligned;
  final Color primaryColor;
  final Color accentColor;
  final Color accentLightColor;
  final Color textColor;
  final Color borderColor;

  _RadarMapPainter({
    required this.userLat,
    required this.userLng,
    required this.qiblaAngle,
    required this.pulseProgress,
    required this.isAligned,
    required this.primaryColor,
    required this.accentColor,
    required this.accentLightColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Clean subtle radar grid rings matched to theme
    final gridPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double r = 0.3; r <= 0.9; r += 0.3) {
      canvas.drawCircle(center, radius * r, gridPaint);
    }

    final crossHairPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossHairPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossHairPaint);

    // 2. Qibla Trajectory Line
    final angleRad = (qiblaAngle - 90.0) * (pi / 180.0);
    final targetDistance = radius * 0.72;
    final kaabaOffset = Offset(
      center.dx + cos(angleRad) * targetDistance,
      center.dy + sin(angleRad) * targetDistance,
    );

    final dashPaint = Paint()
      ..color = (isAligned ? primaryColor : accentColor).withValues(alpha: 0.75)
      ..strokeWidth = 2.0;

    const int segments = 10;
    for (int i = 0; i < segments; i++) {
      if (i % 2 == 0) {
        final t1 = i / segments;
        final t2 = (i + 1) / segments;
        canvas.drawLine(
          Offset.lerp(center, kaabaOffset, t1)!,
          Offset.lerp(center, kaabaOffset, t2)!,
          dashPaint,
        );
      }
    }

    // 3. Animated Pulse Dot
    final particlePos = Offset.lerp(center, kaabaOffset, pulseProgress)!;
    final particlePaint = Paint()
      ..color = isAligned ? primaryColor : accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(particlePos, 3.0, particlePaint);

    // 4. Center User Position Dot
    final userRingPaint = Paint()
      ..color = primaryColor.withValues(alpha: (1.0 - pulseProgress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, 5.0 + (pulseProgress * 10.0), userRingPaint);

    final userDotPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.5, userDotPaint);

    // 5. Kaaba Marker
    final kaabaAuraPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(kaabaOffset, 12.0, kaabaAuraPaint);

    final kaabaCubePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    const cubeSize = 13.0;
    final kaabaRect = Rect.fromCenter(center: kaabaOffset, width: cubeSize, height: cubeSize);
    canvas.drawRRect(RRect.fromRectAndRadius(kaabaRect, const Radius.circular(2.5)), kaabaCubePaint);

    final kiswaPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(RRect.fromRectAndRadius(kaabaRect, const Radius.circular(2.5)), kiswaPaint);

    final bandPaint = Paint()
      ..color = accentLightColor
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(kaabaRect.left, kaabaRect.top + 4),
      Offset(kaabaRect.right, kaabaRect.top + 4),
      bandPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarMapPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.qiblaAngle != qiblaAngle ||
        oldDelegate.primaryColor != primaryColor;
  }
}
