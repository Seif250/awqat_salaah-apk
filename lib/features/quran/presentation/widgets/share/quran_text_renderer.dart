import 'package:flutter/material.dart';
import '../../../data/models/ayah_model.dart';
import '../ayah_rosette.dart';
import 'quran_share_layout_engine.dart';

/// Renders selected Quran verses as a single continuous reading block or paired compact layout.
///
/// Principles:
/// - One continuous flow by default, with optional paired compact layout for short verses.
/// - Consistent typography scale across all lines (NO per-line FittedBox).
/// - Embedded authentic Medina rosettes with Arabic-Indic verse digits.
/// - RTL, centered, comfortable line-height.
class QuranTextRenderer extends StatelessWidget {
  final List<AyahModel> verses;
  final double fontSize;
  final double lineHeight;
  final double rosetteSize;
  final Color textColor;
  final Color goldColor;
  final QuranShareLayoutMode layoutMode;
  final List<List<AyahModel>>? pairedRows;

  const QuranTextRenderer({
    super.key,
    required this.verses,
    this.fontSize = 38.0,
    this.lineHeight = 2.2,
    this.rosetteSize = 46.0,
    this.textColor = const Color(0xFF302923),
    this.goldColor = const Color(0xFFB58A4A),
    this.layoutMode = QuranShareLayoutMode.continuous,
    this.pairedRows,
  });

  @override
  Widget build(BuildContext context) {
    if (verses.isEmpty) {
      return const SizedBox.shrink();
    }

    if (layoutMode == QuranShareLayoutMode.pairedCompact && pairedRows != null && pairedRows!.isNotEmpty) {
      return _buildPairedCompactLayout();
    }

    return _buildContinuousLayout();
  }

  Widget _buildContinuousLayout() {
    final spans = <InlineSpan>[];

    for (final ayah in verses) {
      // 1. Ayah Text
      spans.add(
        TextSpan(
          text: '${ayah.text} ',
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: const ['AmiriQuran'],
            fontSize: fontSize,
            height: lineHeight,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      );

      // 2. Authentic Floral Rosette Medallion
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: AyahRosette(
              ayahNumber: ayah.id,
              size: rosetteSize,
              borderColor: goldColor,
              fillColor: goldColor.withValues(alpha: 0.16),
              textColor: textColor,
            ),
          ),
        ),
      );

      // 3. Trailing space between verses
      spans.add(const TextSpan(text: ' '));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
      ),
    );
  }

  Widget _buildPairedCompactLayout() {
    const double rowGap = 20.0;
    const double colGap = 36.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < pairedRows!.length; r++) ...[
            if (r > 0) const SizedBox(height: rowGap),
            if (pairedRows![r].length == 2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildAyahCell(pairedRows![r][0])),
                  const SizedBox(width: colGap),
                  Expanded(child: _buildAyahCell(pairedRows![r][1])),
                ],
              )
            else
              Center(child: _buildAyahCell(pairedRows![r][0])),
          ],
        ],
      ),
    );
  }

  Widget _buildAyahCell(AyahModel ayah) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${ayah.text} ',
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              fontFamilyFallback: const ['AmiriQuran'],
              fontSize: fontSize,
              height: lineHeight,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AyahRosette(
                ayahNumber: ayah.id,
                size: rosetteSize,
                borderColor: goldColor,
                fillColor: goldColor.withValues(alpha: 0.16),
                textColor: textColor,
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
  }
}
