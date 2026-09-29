import 'package:flutter/material.dart';
import '../../../data/models/ayah_model.dart';
import '../quran_share_composer_dialog.dart' show QuranShareTheme;
import 'share_border_painter.dart';
import 'share_footer_renderer.dart';
import 'share_header_renderer.dart';
import 'share_layout_calculator.dart';
import 'quran_text_renderer.dart';

/// Standalone, resolution-independent Quran Share Canvas Renderer.
///
/// Principles:
/// - 1080px canvas is the SOURCE OF TRUTH.
/// - The canvas dimensions are never determined by the mobile screen or BottomSheet.
/// - Uses authentic Islamic manuscript borders, corner arabesques, and typography.
/// - Fully responsive to dynamic content height.
/// - Supports both direct [pageData] or backward-compatible parameters.
class QuranShareRenderer extends StatelessWidget {
  final SharePageData? pageData;
  final String? surahName;
  final int? startAyah;
  final int? endAyah;
  final List<AyahModel>? verses;
  final QuranShareTheme theme;
  final double? fontSize;
  final String appName;
  final String? crossSurahLabel;

  const QuranShareRenderer({
    super.key,
    this.pageData,
    this.surahName,
    this.startAyah,
    this.endAyah,
    this.verses,
    this.theme = QuranShareTheme.medina,
    this.fontSize,
    this.appName = 'تطبيق وِرد',
    this.crossSurahLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve pageData: either passed directly or calculated from verses
    final resolvedPageData = pageData ??
        ShareLayoutCalculator.calculate(
          surahName: surahName ?? '',
          verses: verses ?? const [],
          fontSize: 38.0 * ((fontSize ?? 22.0) / 22.0),
        ).firstPage;

    Color cardBg;
    Color primaryGold;
    Color secondaryGold;
    Color headerTextColor;
    Color quranTextColor;
    Color footerTextColor;

    switch (theme) {
      case QuranShareTheme.medina:
        cardBg = const Color(0xFFF6F0E4); // لون ورق المصحف السمني الدافئ
        primaryGold = const Color(0xFFB58A4A);
        secondaryGold = const Color(0xFFD8C5A5);
        headerTextColor = const Color(0xFF7A583A);
        quranTextColor = const Color(0xFF302923);
        footerTextColor = const Color(0xFF7A583A);
        break;
      case QuranShareTheme.emerald:
        cardBg = const Color(0xFF0F2D1F);
        primaryGold = const Color(0xFFD4AF37);
        secondaryGold = const Color(0xFFA58A2A);
        headerTextColor = const Color(0xFFE5C158);
        quranTextColor = const Color(0xFFF0EAD6);
        footerTextColor = const Color(0xFFE5C158);
        break;
      case QuranShareTheme.amoled:
        cardBg = const Color(0xFF101412);
        primaryGold = const Color(0xFFC5A059);
        secondaryGold = const Color(0xFF5E5338);
        headerTextColor = const Color(0xFFE5C158);
        quranTextColor = const Color(0xFFEDE8DE);
        footerTextColor = const Color(0xFFC5A059);
        break;
    }

    return SizedBox(
      width: resolvedPageData.canvasWidth,
      height: resolvedPageData.canvasHeight,
      child: Container(
        color: cardBg,
        child: CustomPaint(
          painter: ShareBorderPainter(
            primaryGold: primaryGold,
            secondaryGold: secondaryGold,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (resolvedPageData.canvasWidth - resolvedPageData.contentWidth) / 2.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top margin
                SizedBox(height: resolvedPageData.topPadding),

                // Surah Header
                ShareHeaderRenderer(
                  surahName: resolvedPageData.surahName,
                  goldColor: primaryGold,
                  textColor: headerTextColor,
                ),

                SizedBox(height: resolvedPageData.headerToTextGap),

                // Quran Content Block (Vertically centered when height is at base 4:5)
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: resolvedPageData.contentWidth,
                      child: QuranTextRenderer(
                        verses: resolvedPageData.verses,
                        fontSize: resolvedPageData.fontSize,
                        lineHeight: resolvedPageData.lineHeight,
                        rosetteSize: resolvedPageData.rosetteSize,
                        layoutMode: resolvedPageData.layoutMode,
                        pairedRows: resolvedPageData.pairedRows,
                        textColor: quranTextColor,
                        goldColor: primaryGold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: resolvedPageData.textToFooterGap),

                // Footer Metadata & Branding
                ShareFooterRenderer(
                  surahName: resolvedPageData.surahName,
                  startAyah: resolvedPageData.startAyah,
                  endAyah: resolvedPageData.endAyah,
                  pageIndex: resolvedPageData.pageIndex,
                  totalPages: resolvedPageData.totalPages,
                  goldColor: primaryGold,
                  textColor: footerTextColor,
                  crossSurahLabel: crossSurahLabel,
                ),

                // Bottom margin
                SizedBox(height: resolvedPageData.bottomPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
