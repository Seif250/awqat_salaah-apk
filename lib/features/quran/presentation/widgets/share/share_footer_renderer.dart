import 'package:flutter/material.dart';
import '../../../../../core/utils/arabic_numbers.dart';

/// Renders the refined footer of the Quran share image.
///
/// Contains:
/// - A subtle ornamental divider separating text from footer.
/// - Exact Surah Name and Ayah Range (Arabic digits).
/// - Page indicator if multi-page (e.g. صفحة ١ من ٢).
/// - Subtle, dignified Ward branding.
class ShareFooterRenderer extends StatelessWidget {
  final String surahName;
  final int startAyah;
  final int endAyah;
  final int pageIndex;
  final int totalPages;
  final Color goldColor;
  final Color textColor;
  final String? crossSurahLabel;

  const ShareFooterRenderer({
    super.key,
    required this.surahName,
    required this.startAyah,
    required this.endAyah,
    this.pageIndex = 1,
    this.totalPages = 1,
    this.goldColor = const Color(0xFFB58A4A),
    this.textColor = const Color(0xFF7A583A),
    this.crossSurahLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the range text
    String rangeText;
    if (crossSurahLabel != null && crossSurahLabel!.isNotEmpty) {
      rangeText = crossSurahLabel!;
    } else if (startAyah == endAyah) {
      rangeText = 'سورة $surahName • الآية ${toArabicDigits(startAyah)}';
    } else {
      rangeText = 'سورة $surahName • الآيات ${toArabicDigits(startAyah)}–${toArabicDigits(endAyah)}';
    }

    if (totalPages > 1) {
      rangeText += ' (${toArabicDigits(pageIndex)} / ${toArabicDigits(totalPages)})';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ornamental divider
        CustomPaint(
          size: const Size(480, 14),
          painter: _FooterDividerPainter(goldColor: goldColor),
        ),

        const SizedBox(height: 12),

        // Footer Metadata Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Surah & Ayah Range
              Expanded(
                child: Text(
                  rangeText,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 12),

              // Subtle Ward App Branding
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mosque_rounded,
                    size: 16.0,
                    color: goldColor.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'تطبيق وِرد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17.0,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.85),
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FooterDividerPainter extends CustomPainter {
  final Color goldColor;

  _FooterDividerPainter({required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final centerX = size.width / 2;

    final linePaint = Paint()
      ..color = goldColor.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left line
    canvas.drawLine(Offset(10, centerY), Offset(centerX - 20, centerY), linePaint);

    // Right line
    canvas.drawLine(Offset(centerX + 20, centerY), Offset(size.width - 10, centerY), linePaint);

    // Central small rosette diamond
    final diamond = Path()
      ..moveTo(centerX, centerY - 5)
      ..lineTo(centerX + 6, centerY)
      ..lineTo(centerX, centerY + 5)
      ..lineTo(centerX - 6, centerY)
      ..close();

    canvas.drawPath(diamond, Paint()..color = goldColor..style = PaintingStyle.fill);

    // Flanking tiny dots
    canvas.drawCircle(Offset(centerX - 12, centerY), 1.5, Paint()..color = goldColor);
    canvas.drawCircle(Offset(centerX + 12, centerY), 1.5, Paint()..color = goldColor);
  }

  @override
  bool shouldRepaint(covariant _FooterDividerPainter oldDelegate) =>
      oldDelegate.goldColor != goldColor;
}
