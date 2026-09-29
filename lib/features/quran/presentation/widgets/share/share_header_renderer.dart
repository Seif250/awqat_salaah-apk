import 'package:flutter/material.dart';

/// Renders a classical Islamic manuscript Surah header.
///
/// Avoids modern UI button pills. Uses traditional horizontal decorative wings
/// and a refined ornamental divider with central diamond rosette.
class ShareHeaderRenderer extends StatelessWidget {
  final String surahName;
  final Color goldColor;
  final Color textColor;

  const ShareHeaderRenderer({
    super.key,
    required this.surahName,
    this.goldColor = const Color(0xFFB58A4A),
    this.textColor = const Color(0xFF7A583A),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top ornate title row with manuscript wings
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left ornamental wing
            Flexible(
              child: CustomPaint(
                size: const Size(90, 24),
                painter: _HeaderWingPainter(goldColor: goldColor, isLeft: true),
              ),
            ),
            const SizedBox(width: 14),

            // Surah Title in traditional manuscript calligraphy
            Text(
              'سُورَةُ $surahName',
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontFamilyFallback: const ['UthmanicHafs', 'Cairo', 'serif'],
                fontSize: 34.0,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.2,
                letterSpacing: 0.5,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 14),

            // Right ornamental wing
            Flexible(
              child: CustomPaint(
                size: const Size(90, 24),
                painter: _HeaderWingPainter(goldColor: goldColor, isLeft: false),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Delicate ornamental divider with central diamond
        CustomPaint(
          size: const Size(360, 16),
          painter: _HeaderDividerPainter(goldColor: goldColor),
        ),
      ],
    );
  }
}

class _HeaderWingPainter extends CustomPainter {
  final Color goldColor;
  final bool isLeft;

  _HeaderWingPainter({required this.goldColor, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.save();
    if (!isLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final centerY = size.height / 2;

    // Horizontal tapering spine
    final spine = Path()
      ..moveTo(0, centerY)
      ..lineTo(size.width - 24, centerY);
    canvas.drawPath(spine, paint);

    // Decorative curled leaf / finial at outer tip
    final finial = Path()
      ..moveTo(size.width - 24, centerY)
      ..cubicTo(size.width - 16, centerY - 8, size.width - 8, centerY - 6, size.width, centerY)
      ..cubicTo(size.width - 8, centerY + 6, size.width - 16, centerY + 8, size.width - 24, centerY);
    canvas.drawPath(finial, fillPaint);
    canvas.drawPath(finial, paint);

    // Central leaf accent
    final leaf = Path()
      ..moveTo(size.width * 0.45, centerY)
      ..quadraticBezierTo(size.width * 0.55, centerY - 6, size.width * 0.65, centerY)
      ..quadraticBezierTo(size.width * 0.55, centerY + 6, size.width * 0.45, centerY);
    canvas.drawPath(leaf, fillPaint);
    canvas.drawPath(leaf, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HeaderWingPainter oldDelegate) =>
      oldDelegate.goldColor != goldColor || oldDelegate.isLeft != isLeft;
}

class _HeaderDividerPainter extends CustomPainter {
  final Color goldColor;

  _HeaderDividerPainter({required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final centerX = size.width / 2;

    final linePaint = Paint()
      ..color = goldColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left line with fade
    canvas.drawLine(Offset(20, centerY), Offset(centerX - 24, centerY), linePaint);

    // Right line with fade
    canvas.drawLine(Offset(centerX + 24, centerY), Offset(size.width - 20, centerY), linePaint);

    // Central diamond rosette
    final diamond = Path()
      ..moveTo(centerX, centerY - 7)
      ..lineTo(centerX + 8, centerY)
      ..lineTo(centerX, centerY + 7)
      ..lineTo(centerX - 8, centerY)
      ..close();

    canvas.drawPath(
      diamond,
      Paint()
        ..color = goldColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      diamond,
      Paint()
        ..color = goldColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Flanking dots
    canvas.drawCircle(Offset(centerX - 16, centerY), 2.0, Paint()..color = goldColor);
    canvas.drawCircle(Offset(centerX + 16, centerY), 2.0, Paint()..color = goldColor);
  }

  @override
  bool shouldRepaint(covariant _HeaderDividerPainter oldDelegate) =>
      oldDelegate.goldColor != goldColor;
}
