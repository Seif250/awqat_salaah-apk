import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';

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
  double _zoomLevel = 1.0;

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
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return ClipOval(
          child: Container(
            color: const Color(0xFF0D1C14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Custom Canvas painting the radar grid, continental arcs, user location, Kaaba and trajectory beam
                AnimatedRotation(
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
                      zoom: _zoomLevel,
                    ),
                  ),
                ),

                // Controls inside the radar: Zoom in/out buttons
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSmallButton(
                        icon: Icons.add_rounded,
                        onTap: () {
                          if (_zoomLevel < 2.0) {
                            setState(() => _zoomLevel += 0.25);
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildSmallButton(
                        icon: Icons.remove_rounded,
                        onTap: () {
                          if (_zoomLevel > 0.6) {
                            setState(() => _zoomLevel -= 0.25);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                // Distance indicator tag in the center-top
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accentGold.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'المسافة إلى مكة: ${toArabicDigits(widget.distanceKm.round())} كم',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGoldLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmallButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 14),
      ),
    );
  }
}

class _RadarMapPainter extends CustomPainter {
  final double userLat;
  final double userLng;
  final double qiblaAngle;
  final double pulseProgress;
  final bool isAligned;
  final double zoom;

  _RadarMapPainter({
    required this.userLat,
    required this.userLng,
    required this.qiblaAngle,
    required this.pulseProgress,
    required this.isAligned,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw radar circular grids
    final gridPaint = Paint()
      ..color = const Color(0xFF1B3D2B).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double r = 0.25; r <= 1.0; r += 0.25) {
      canvas.drawCircle(center, radius * r, gridPaint);
    }

    // Radar crosshairs
    final crossHairPaint = Paint()
      ..color = const Color(0xFF1B3D2B).withValues(alpha: 0.3)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossHairPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossHairPaint);

    // 2. Simulated geographical landmass / map terrain arcs (Stylized Middle East & Arabia radar map)
    final mapTerrainPaint = Paint()
      ..color = const Color(0xFF133824).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final terrainPath = Path();
    // Stylized Red Sea / Gulf / Sinai continental shapes
    terrainPath.moveTo(center.dx - radius * 0.4 * zoom, center.dy - radius * 0.6 * zoom);
    terrainPath.quadraticBezierTo(
      center.dx - radius * 0.1 * zoom,
      center.dy - radius * 0.2 * zoom,
      center.dx + radius * 0.3 * zoom,
      center.dy - radius * 0.5 * zoom,
    );
    terrainPath.quadraticBezierTo(
      center.dx + radius * 0.6 * zoom,
      center.dy + radius * 0.1 * zoom,
      center.dx + radius * 0.4 * zoom,
      center.dy + radius * 0.5 * zoom,
    );
    terrainPath.quadraticBezierTo(
      center.dx - radius * 0.1 * zoom,
      center.dy + radius * 0.4 * zoom,
      center.dx - radius * 0.5 * zoom,
      center.dy + radius * 0.2 * zoom,
    );
    terrainPath.close();
    canvas.drawPath(terrainPath, mapTerrainPaint);

    // 3. Qibla Geodesic Vector Trajectory Beam
    final angleRad = (qiblaAngle - 90.0) * (pi / 180.0);
    final targetDistance = radius * 0.72;
    final kaabaOffset = Offset(
      center.dx + cos(angleRad) * targetDistance,
      center.dy + sin(angleRad) * targetDistance,
    );

    // Draw dashed / glowing trajectory line
    final dashPaint = Paint()
      ..color = isAligned ? AppColors.accentGoldLight : const Color(0xFF81C784)
      ..strokeWidth = 2.0;

    const int segments = 12;
    for (int i = 0; i < segments; i++) {
      if (i % 2 == 0) {
        final t1 = i / segments;
        final t2 = (i + 1) / segments;
        final p1 = Offset.lerp(center, kaabaOffset, t1)!;
        final p2 = Offset.lerp(center, kaabaOffset, t2)!;
        canvas.drawLine(p1, p2, dashPaint);
      }
    }

    // 4. Moving Pulse particle along the trajectory
    final particlePos = Offset.lerp(center, kaabaOffset, pulseProgress)!;
    final particlePaint = Paint()
      ..color = isAligned ? Colors.amberAccent : Colors.lightGreenAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(particlePos, 3.5, particlePaint);

    // 5. User Position marker at center
    final userRingPaint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: 1.0 - pulseProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 6.0 + (pulseProgress * 12.0), userRingPaint);

    final userDotPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5.0, userDotPaint);

    // User Label
    final userTextSpan = TextSpan(
      text: 'أنت',
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
    final userTextPainter = TextPainter(
      text: userTextSpan,
      textDirection: TextDirection.rtl,
    )..layout();
    userTextPainter.paint(
      canvas,
      Offset(center.dx - userTextPainter.width / 2, center.dy + 8),
    );

    // 6. Kaaba Marker at target location
    // Kaaba glowing aura
    final kaabaAuraPaint = Paint()
      ..color = AppColors.accentGold.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(kaabaOffset, 12.0, kaabaAuraPaint);

    // Kaaba Cube representation
    final kaabaCubePaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    const cubeSize = 13.0;
    final kaabaRect = Rect.fromCenter(center: kaabaOffset, width: cubeSize, height: cubeSize);
    canvas.drawRRect(RRect.fromRectAndRadius(kaabaRect, const Radius.circular(2.5)), kaabaCubePaint);

    // Gold Kiswa border on Kaaba Cube
    final kiswaPaint = Paint()
      ..color = AppColors.accentGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(RRect.fromRectAndRadius(kaabaRect, const Radius.circular(2.5)), kiswaPaint);

    // Kaaba Gold Band
    final bandPaint = Paint()
      ..color = AppColors.accentGoldLight
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(kaabaRect.left, kaabaRect.top + 4),
      Offset(kaabaRect.right, kaabaRect.top + 4),
      bandPaint,
    );

    // Kaaba Label
    final kaabaTextSpan = TextSpan(
      text: 'مكة',
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: AppColors.accentGoldLight,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 4,
          ),
        ],
      ),
    );
    final kaabaTextPainter = TextPainter(
      text: kaabaTextSpan,
      textDirection: TextDirection.rtl,
    )..layout();
    kaabaTextPainter.paint(
      canvas,
      Offset(kaabaOffset.dx - kaabaTextPainter.width / 2, kaabaOffset.dy + 10),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarMapPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.isAligned != isAligned ||
        oldDelegate.zoom != zoom ||
        oldDelegate.qiblaAngle != qiblaAngle;
  }
}
