import 'package:flutter/material.dart';

/// CustomPainter for rendering an authentic Islamic manuscript frame.
///
/// Features:
/// - Triple nested gold rules: Outer hairline, Middle prominent gold band, Inner soft beige rule.
/// - Symmetrical arabesque corner ornaments in all four corners.
/// - Fully responsive to dynamic canvas width & height (normalized coordinates).
class ShareBorderPainter extends CustomPainter {
  final Color primaryGold;
  final Color secondaryGold;

  const ShareBorderPainter({
    this.primaryGold = const Color(0xFFB58A4A),
    this.secondaryGold = const Color(0xFFD8C5A5),
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double outerMargin = 38.0;
    final outerRect = Rect.fromLTWH(
      outerMargin,
      outerMargin,
      size.width - outerMargin * 2,
      size.height - outerMargin * 2,
    );

    // 1. Outer hairline rule (1.8px)
    final outerPaint = Paint()
      ..color = primaryGold.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRect(outerRect, outerPaint);

    // 2. Middle primary gold rule (3.0px)
    const double middleInset = 7.0;
    final middleRect = outerRect.deflate(middleInset);
    final middlePaint = Paint()
      ..color = primaryGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(middleRect, middlePaint);

    // 3. Inner soft beige rule (1.2px)
    const double innerInset = 6.0;
    final innerRect = middleRect.deflate(innerInset);
    final innerPaint = Paint()
      ..color = secondaryGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRect(innerRect, innerPaint);

    // 4. Four symmetrical corner ornaments
    _drawCornerOrnament(canvas, innerRect.topLeft, 1, 1); // Top-Left
    _drawCornerOrnament(canvas, innerRect.topRight, -1, 1); // Top-Right
    _drawCornerOrnament(canvas, innerRect.bottomLeft, 1, -1); // Bottom-Left
    _drawCornerOrnament(canvas, innerRect.bottomRight, -1, -1); // Bottom-Right
  }

  void _drawCornerOrnament(Canvas canvas, Offset origin, double scaleX, double scaleY) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scaleX, scaleY);

    final ornamentPaint = Paint()
      ..color = primaryGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = primaryGold.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // Corner L-bracket step
    final cornerPath = Path()
      ..moveTo(0, 36)
      ..lineTo(0, 0)
      ..lineTo(36, 0);
    canvas.drawPath(cornerPath, ornamentPaint);

    // Secondary stepped inner contour
    final innerStep = Path()
      ..moveTo(6, 30)
      ..lineTo(6, 6)
      ..lineTo(30, 6);
    canvas.drawPath(
      innerStep,
      Paint()
        ..color = secondaryGold.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Inward pointing diagonal arabesque leaf/palmette (at 45 degrees)
    final palmette = Path()
      ..moveTo(12, 12)
      ..quadraticBezierTo(26, 16, 34, 34)
      ..quadraticBezierTo(16, 26, 12, 12);
    canvas.drawPath(palmette, fillPaint);
    canvas.drawPath(palmette, ornamentPaint);

    // Central diamond knot
    final diamond = Path()
      ..moveTo(23, 20)
      ..lineTo(26, 23)
      ..lineTo(23, 26)
      ..lineTo(20, 23)
      ..close();
    canvas.drawPath(diamond, Paint()..color = primaryGold..style = PaintingStyle.fill);

    // Subtle decorative finials on arm ends
    canvas.drawCircle(const Offset(0, 40), 2.2, Paint()..color = primaryGold..style = PaintingStyle.fill);
    canvas.drawCircle(const Offset(40, 0), 2.2, Paint()..color = primaryGold..style = PaintingStyle.fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ShareBorderPainter oldDelegate) {
    return oldDelegate.primaryGold != primaryGold ||
        oldDelegate.secondaryGold != secondaryGold;
  }
}
