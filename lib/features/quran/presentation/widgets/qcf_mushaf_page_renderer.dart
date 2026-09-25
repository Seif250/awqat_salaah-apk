import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/qcf_page_model.dart';
import 'ayah_gesture_recognizer.dart';
import 'ayah_rosette.dart';

/// Authentic Medina Mushaf Page Renderer using Quran Foundation QCF V2 data.
/// Renders a deterministic 15-line composition on a rigid 385 x 620 coordinate canvas,
/// scaled proportionally via AspectRatio and FittedBox.
class QcfMushafPageRenderer extends StatefulWidget {
  final QcfPageModel pageModel;
  final bool isNightMode;
  final int? highlightedAyahId;
  final int? highlightedSurahId;
  final Map<String, dynamic> selectedAyat;
  final Set<String> bookmarks;
  final List<BookmarkModel> richBookmarks;
  final int juz;
  final int hizb;
  final String surahName;
  final void Function({required int surahId, required int ayahId}) onAyahTap;
  final void Function({required int surahId, required int ayahId}) onAyahLongPress;
  final VoidCallback onPageTap;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;

  const QcfMushafPageRenderer({
    super.key,
    required this.pageModel,
    required this.isNightMode,
    this.highlightedAyahId,
    this.highlightedSurahId,
    this.selectedAyat = const {},
    this.bookmarks = const {},
    this.richBookmarks = const [],
    required this.juz,
    required this.hizb,
    required this.surahName,
    required this.onAyahTap,
    required this.onAyahLongPress,
    required this.onPageTap,
    this.onNextPage,
    this.onPreviousPage,
  });

  // Authentic Medina Mushaf reference geometry
  static const double kCanvasWidth = 385.0;
  static const double kCanvasHeight = 620.0;
  static const double kReadingWidth = 353.0; // 385 - 32 (16 left + 16 right)

  // Authentic Medina Mushaf Traditional Color Palette (Exact Specifications)
  static const Color paperBg = Color(0xFFF6F0E4);
  static const Color textDark = Color(0xFF302923);
  static const Color secondaryText = Color(0xFF6F6255);
  static const Color goldAccent = Color(0xFFB58A4A);
  static const Color dividerColor = Color(0xFFD8C7A8);

  // Night Mode Alternatives
  static const Color nightPaper = Color(0xFF1B201D);
  static const Color nightText = Color(0xFFE8E5DD);
  static const Color nightSecondary = Color(0xFFB5A99B);
  static const Color nightGold = Color(0xFFD4AF37);
  static const Color nightDivider = Color(0xFF2E3832);

  @override
  State<QcfMushafPageRenderer> createState() => _QcfMushafPageRendererState();
}

class _QcfMushafPageRendererState extends State<QcfMushafPageRenderer> {
  @override
  Widget build(BuildContext context) {
    final pageNum = widget.pageModel.page;
    final bgPaper = widget.isNightMode ? QcfMushafPageRenderer.nightPaper : QcfMushafPageRenderer.paperBg;
    final textDarkColor = widget.isNightMode ? QcfMushafPageRenderer.nightText : QcfMushafPageRenderer.textDark;
    final secondary = widget.isNightMode ? QcfMushafPageRenderer.nightSecondary : QcfMushafPageRenderer.secondaryText;
    final gold = widget.isNightMode ? QcfMushafPageRenderer.nightGold : QcfMushafPageRenderer.goldAccent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;

        // 1. Proportional side margins:
        // Tight margins to maximize reading area while keeping glyphs safe.
        final maxReadingWidth = viewportHeight * 0.78;
        final horizontalMargin = (viewportWidth * 0.035).clamp(8.0, 18.0);
        final readingWidth = (viewportWidth - 2 * horizontalMargin).clamp(0.0, maxReadingWidth);

        // 2. The Quran fills the entire available height with no extra top padding
        final double availableLinesHeight = viewportHeight.clamp(100.0, viewportHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPageTap,
          child: Container(
            color: bgPaper,
            width: viewportWidth,
            height: viewportHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full viewport Mushaf reading column - fills entire space
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: readingWidth,
                    height: viewportHeight,
                    child: _buildLinesCanvas(
                      pageNum,
                      textDarkColor,
                      secondary,
                      gold,
                      readingWidth,
                      availableLinesHeight,
                    ),
                  ),
                ),

                // Tap Left Edge -> Previous Page
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 44,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onPreviousPage,
                  ),
                ),

                // Tap Right Edge -> Next Page
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 44,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onNextPage,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Renders all lines of the page with authentic proportions and line rhythm.
  Widget _buildLinesCanvas(
    int pageNum,
    Color textDark,
    Color secondary,
    Color gold,
    double readingWidth,
    double availableLinesHeight,
  ) {
    final lines = widget.pageModel.lines;

    // ── PAGE 1: Al-Fatihah ──────────────────────────────────────────────────
    // Authentic opening page: 7 lines, vertically centered with graceful breathing space
    if (pageNum == 1) {
      final p1SlotHeight = (availableLinesHeight / 9.5).clamp(44.0, 54.0);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: SizedBox(
                  height: p1SlotHeight,
                  child: _buildLine(
                    line,
                    pageNum,
                    textDark,
                    secondary,
                    gold,
                    readingWidth,
                    p1SlotHeight,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // ── PAGE 2: Al-Baqarah 1-5 ──────────────────────────────────────────────
    // Authentic opening page: 8 lines, vertically balanced.
    // Lines 3-7 are full lines that occupy reading width naturally.
    // Line 8 is the concluding centered verse.
    if (pageNum == 2) {
      final p2SlotHeight = (availableLinesHeight / 10.5).clamp(44.0, 54.0);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.5),
                child: SizedBox(
                  height: p2SlotHeight,
                  child: _buildLine(
                    line,
                    pageNum,
                    textDark,
                    secondary,
                    gold,
                    readingWidth,
                    p2SlotHeight,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // ── PAGES 3-604: Standard 15-Line Pages ──────────────────────────────────
    // Exactly 15 lines filling the entire available reading area from top to bottom
    final double lineSlotHeight = availableLinesHeight / 15.0;
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          SizedBox(
            height: lineSlotHeight,
            child: _buildLine(
              line,
              pageNum,
              textDark,
              secondary,
              gold,
              readingWidth,
              lineSlotHeight,
            ),
          ),
      ],
    );
  }

  /// Dispatches line rendering based on its type.
  Widget _buildLine(
    QcfLineModel line,
    int pageNum,
    Color textDark,
    Color secondary,
    Color gold,
    double readingWidth,
    double slotHeight,
  ) {
    if (line.isSurahHeader) {
      return _buildSurahHeaderBanner(line, textDark, gold, readingWidth, slotHeight);
    }
    if (line.isBasmala) {
      return _buildBasmalaLine(line, textDark, readingWidth, slotHeight);
    }
    return _buildTextLine(line, pageNum, textDark, gold, readingWidth, slotHeight);
  }

  /// Calligraphic Surah Header Banner with traditional Islamic framing.
  Widget _buildSurahHeaderBanner(
    QcfLineModel line,
    Color textColor,
    Color gold,
    double readingWidth,
    double slotHeight,
  ) {
    final bgBanner = widget.isNightMode ? const Color(0xFF1E2420) : const Color(0xFFF9F5EC);
    final borderCol = gold.withValues(alpha: widget.isNightMode ? 0.6 : 0.7);
    final surahTitle = line.text ?? 'سُورَةُ ٱلْقُرْآنِ';
    final bannerHeight = (slotHeight * 0.82).clamp(32.0, 42.0);

    return Center(
      child: Container(
        height: bannerHeight,
        width: readingWidth,
        margin: const EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: bgBanner,
          border: Border.all(color: borderCol, width: 1.0),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(readingWidth, bannerHeight),
              painter: _BannerOrnamentsPainter(color: borderCol),
            ),
            Text(
              surahTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: (bannerHeight * 0.44).clamp(13.5, 16.0),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calligraphic Basmalah Line
  Widget _buildBasmalaLine(
    QcfLineModel line,
    Color textColor,
    double readingWidth,
    double slotHeight,
  ) {
    const glyphText = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0),
          child: Text(
            glyphText,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontFamilyFallback: const ['Amiri', 'serif'],
              fontSize: (slotHeight * 0.58).clamp(22.0, 26.0),
              height: 1.3,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Deterministic Text Line with individual word hit-targets, highlights,
  /// and traditional gold Ayah markers.
  Widget _buildTextLine(
    QcfLineModel line,
    int pageNum,
    Color textDark,
    Color gold,
    double readingWidth,
    double slotHeight,
  ) {
    if (line.words.isEmpty) {
      return const SizedBox.shrink();
    }

    const fontFam = 'AmiriQuran';

    // Proportional font sizing:
    // Opening pages 1 & 2 have generous, readable font size. Standard pages scale with readingWidth.
    final double wordFontSize = (pageNum == 1)
        ? 26.0
        : ((pageNum == 2)
            ? 25.0
            : (readingWidth / 15.5).clamp(20.0, 25.0));

    // Line centering logic:
    // Page 1: all lines centered.
    // Page 2: lines 3-7 are full justified lines; line 8 is the short concluding line (centered).
    // Standard pages: only short final lines of a surah are centered.
    final bool isPage1 = pageNum == 1;
    final bool isLastLineOfPage2 = pageNum == 2 && line.line == 8;
    final bool isShortFinalLine = (line.words.length < 5 && line.line == 15);
    final bool isCentered = isPage1 || isLastLineOfPage2 || isShortFinalLine;

    final spans = <InlineSpan>[];
    for (int i = 0; i < line.words.length; i++) {
      final word = line.words[i];
      spans.add(_buildWordSpan(
        word: word,
        fontFamily: fontFam,
        wordFontSize: wordFontSize,
        isLastWord: i == line.words.length - 1,
        goldColor: gold,
      ));
    }

    // Full lines: FittedBox.fitWidth scales text to exactly fill the
    // available width. The text is unconstrained so FittedBox sees its
    // true natural width and calculates the correct scale factor.
    // Centered (short) lines: scaleDown so they don't get stretched.
    if (isCentered) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(children: spans),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            softWrap: false,
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.center,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          softWrap: false,
        ),
      ),
    );
  }

  InlineSpan _buildWordSpan({
    required QcfWordModel word,
    required String fontFamily,
    required double wordFontSize,
    required bool isLastWord,
    required Color goldColor,
  }) {
    final surahId = word.surahId ?? 1;
    final ayahId = word.ayahId ?? 1;
    final ayahKey = '$surahId:$ayahId';

    final isSelected = widget.selectedAyat.containsKey(ayahKey);
    final isHighlighted = widget.highlightedAyahId == ayahId &&
        (widget.highlightedSurahId == null || widget.highlightedSurahId == surahId);
    final anyHighlighted = widget.highlightedAyahId != null;

    // Check bookmarks
    BookmarkModel? richBk;
    for (final b in widget.richBookmarks) {
      if (b.surahId == surahId && b.ayahNumber == ayahId) {
        richBk = b;
        break;
      }
    }
    final isBookmarked = richBk != null || widget.bookmarks.contains(ayahKey);
    final bookmarkColor = richBk != null
        ? Color(int.parse(richBk.color.replaceFirst('#', '0xFF')))
        : const Color(0xFF2E7D32);

    // Compute text color (Warm dark charcoal-brown #302923)
    Color wordTextColor;
    if (isSelected) {
      wordTextColor = widget.isNightMode
          ? AppColors.accentGoldLight
          : const Color(0xFF8C5D00);
    } else if (isHighlighted) {
      wordTextColor = widget.isNightMode
          ? const Color(0xFFFDE68A)
          : const Color(0xFF78350F);
    } else if (anyHighlighted) {
      wordTextColor = widget.isNightMode
          ? QcfMushafPageRenderer.nightText.withValues(alpha: 0.55)
          : QcfMushafPageRenderer.textDark.withValues(alpha: 0.65);
    } else {
      wordTextColor = widget.isNightMode
          ? QcfMushafPageRenderer.nightText
          : QcfMushafPageRenderer.textDark;
    }

    // Compute background highlight color (Soft translucent warm tones)
    Color? wordBgColor;
    if (isSelected) {
      wordBgColor = AppColors.accentGold.withValues(alpha: 0.28);
    } else if (isHighlighted) {
      wordBgColor = AppColors.accentGold
          .withValues(alpha: widget.isNightMode ? 0.32 : 0.20);
    } else if (isBookmarked) {
      wordBgColor = bookmarkColor.withValues(alpha: 0.12);
    }

    final suffix = isLastWord ? '' : ' ';

    // Word with Ayah end rosette:
    if (word.isAyahEnd) {
      final cleanWord = word.word.replaceAll(RegExp(r'[٠-٩0-9]+'), '').trim();
      return TextSpan(
        children: [
          if (cleanWord.isNotEmpty)
            TextSpan(
              text: '$cleanWord ',
              recognizer: AyahGestureRecognizer()
                ..onTap = () {
                  widget.onAyahTap(surahId: surahId, ayahId: ayahId);
                }
                ..onLongPress = () {
                  widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
                },
              style: TextStyle(
                fontFamily: fontFamily,
                fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                fontSize: wordFontSize,
                fontWeight: FontWeight.w400,
                color: wordTextColor,
                backgroundColor: wordBgColor,
                height: 1.32,
              ),
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            style: TextStyle(
              backgroundColor: wordBgColor,
            ),
            child: GestureDetector(
              onTap: () => widget.onAyahTap(surahId: surahId, ayahId: ayahId),
              onLongPress: () => widget.onAyahLongPress(surahId: surahId, ayahId: ayahId),
              child: Container(
                color: wordBgColor,
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AyahRosette(
                  ayahNumber: ayahId,
                  size: (wordFontSize * 0.95).clamp(20.0, 25.0),
                  borderColor: goldColor,
                  textColor: goldColor,
                  highlightBgColor: wordBgColor,
                ),
              ),
            ),
          ),
          if (!isLastWord) const TextSpan(text: ' '),
        ],
      );
    }

    // Standard word rendering
    return TextSpan(
      text: '${word.word}$suffix',
      recognizer: AyahGestureRecognizer()
        ..onTap = () {
          widget.onAyahTap(surahId: surahId, ayahId: ayahId);
        }
        ..onLongPress = () {
          widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
        },
      style: TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
        fontSize: wordFontSize,
        fontWeight: FontWeight.w400,
        color: wordTextColor,
        backgroundColor: wordBgColor,
        height: 1.32,
      ),
    );
  }
}


/// Subtle ornamental corner and side flourishes for Surah Header Banner
class _BannerOrnamentsPainter extends CustomPainter {
  final Color color;

  const _BannerOrnamentsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    const pad = 3.5;
    final w = size.width;
    final h = size.height;

    // Corner decorative markers
    _drawDiamond(canvas, fill, pad + 3, h / 2, 2.5);
    _drawDiamond(canvas, fill, w - pad - 3, h / 2, 2.5);

    // Left and right delicate frame accents
    canvas.drawLine(Offset(pad + 8, h / 2), Offset(pad + 24, h / 2), stroke);
    canvas.drawLine(Offset(w - pad - 24, h / 2), Offset(w - pad - 8, h / 2), stroke);
  }

  void _drawDiamond(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BannerOrnamentsPainter old) => old.color != color;
}
