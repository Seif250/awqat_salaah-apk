import 'package:flutter/material.dart';
import '../../data/models/surah_model.dart';

/// Ornate Islamic Banner for Surah Heading (as in Medina Mushaf)
class MushafSurahBanner extends StatelessWidget {
  final SurahModel surah;
  final bool isDark;

  const MushafSurahBanner({
    super.key,
    required this.surah,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    const bronzeColor = Color(0xFF8C643E);
    const goldColor = Color(0xFFB89368);
    final cardBg = isDark ? const Color(0xFF1E2420) : const Color(0xFFFBF8F0);
    final cartoucheBg = isDark ? const Color(0xFF262E2A) : const Color(0xFFF6F0E4);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      height: 52,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: goldColor.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : goldColor).withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Arabesque Texture / Borders
          Positioned.fill(
            child: CustomPaint(
              painter: _BannerOrnamentsPainter(
                color: goldColor.withValues(alpha: isDark ? 0.35 : 0.45),
              ),
            ),
          ),

          // Central Cartouche with Surah Name
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
              decoration: BoxDecoration(
                color: cartoucheBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: bronzeColor.withValues(alpha: 0.7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                'سُورَةُ ${surah.name}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE8D7B8) : const Color(0xFF4A341E),
                  height: 1.4,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerOrnamentsPainter extends CustomPainter {
  final Color color;

  _BannerOrnamentsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Inner thin border
    canvas.drawRect(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      paint,
    );

    // Left and Right arabesque corner brackets
    const cornerSize = 16.0;

    // Top-left
    canvas.drawLine(const Offset(6, 6), const Offset(6 + cornerSize, 6), paint);
    canvas.drawLine(const Offset(6, 6), const Offset(6, 6 + cornerSize), paint);

    // Bottom-left
    canvas.drawLine(Offset(6, size.height - 6), Offset(6 + cornerSize, size.height - 6), paint);
    canvas.drawLine(Offset(6, size.height - 6), Offset(6, size.height - 6 - cornerSize), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - 6, 6), Offset(size.width - 6 - cornerSize, 6), paint);
    canvas.drawLine(Offset(size.width - 6, 6), Offset(size.width - 6, 6 + cornerSize), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - 6, size.height - 6), Offset(size.width - 6 - cornerSize, size.height - 6), paint);
    canvas.drawLine(Offset(size.width - 6, size.height - 6), Offset(size.width - 6, size.height - 6 - cornerSize), paint);
  }

  @override
  bool shouldRepaint(covariant _BannerOrnamentsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
