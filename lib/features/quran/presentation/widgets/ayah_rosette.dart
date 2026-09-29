import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/arabic_numbers.dart';

/// Authentic Medina Mushaf Ayah End Marker (Floral Rosette Medallion)
class AyahRosette extends StatelessWidget {
  final int ayahNumber;
  final double size;
  final Color? borderColor;
  final Color? fillColor;
  final Color? textColor;
  final Color? highlightBgColor;
  final EdgeInsetsGeometry? padding;

  const AyahRosette({
    super.key,
    required this.ayahNumber,
    this.size = 28.0,
    this.borderColor,
    this.fillColor,
    this.textColor,
    this.highlightBgColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    const defaultBorder = Color(0xFFA67C4A);
    const defaultFill = Color(0xFFF7F1E1);
    const defaultText = Color(0xFF382A1B);

    final border = borderColor ?? defaultBorder;
    final fill = fillColor ?? defaultFill;
    final text = textColor ?? defaultText;
    final contentPadding = padding ?? const EdgeInsets.symmetric(horizontal: 1.5);

    Widget rosetteWidget = Padding(
      padding: contentPadding,
      child: CustomPaint(
        size: Size(size, size),
        painter: _RosettePainter(
          borderColor: border,
          fillColor: fill,
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              toArabicDigits(ayahNumber),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontFamilyFallback: const ['Cairo', 'serif'],
                fontSize: size * 0.44,
                fontWeight: FontWeight.bold,
                color: text,
                height: 1.05,
              ),
            ),
          ),
        ),
      ),
    );

    if (highlightBgColor != null) {
      return Container(
        color: highlightBgColor,
        child: rosetteWidget,
      );
    }

    return rosetteWidget;
  }
}

class _RosettePainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;

  _RosettePainter({
    required this.borderColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Paint for background fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    // Paint for outer petals
    final petalPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    // Paint for outer ring
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    // 1. Draw outer 8 floral points (petals)
    const int petalCount = 8;
    final petalRadius = radius * 0.92;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi) / petalCount;
      final x = center.dx + petalRadius * math.cos(angle);
      final y = center.dy + petalRadius * math.sin(angle);
      canvas.drawCircle(Offset(x, y), size.width * 0.075, petalPaint);
    }

    // 2. Draw circular medallion base
    canvas.drawCircle(center, radius * 0.78, fillPaint);

    // 3. Draw outer stroke ring
    canvas.drawCircle(center, radius * 0.78, strokePaint);

    // 4. Draw inner decorative ring
    final innerStrokePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55;
    canvas.drawCircle(center, radius * 0.65, innerStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _RosettePainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.fillColor != fillColor;
  }
}
