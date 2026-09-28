import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/qcf_page_model.dart';
import '../../services/qcf_font_service.dart';
import 'ayah_gesture_recognizer.dart';
import 'ayah_rosette.dart';

/// Reading Theme modes matching Golden Quran aesthetics
enum MushafThemeMode {
  ivory, // Royal Ivory (عاجي ملكي - ورق المصحف الكلاسيكي)
  sepia, // Antique Sepia (بيج تراثي - مريح للعينين نهاراً)
  night, // Quiet Night (ليلي هادئ - أسود داكن بدون وهج)
}

/// Authentic Medina Mushaf Page Renderer (Golden Quran vector architecture).
/// Replicates the majestic layout of the King Fahd Medina Mushaf:
/// - Ornate double-line Islamic page frame with corner arabesques.
/// - Top header with Surah name, Juz, and center ornamental medallion.
/// - Full-width line justification so the 15 lines form a solid, rectangular block.
/// - Calligraphic Surah title banners with illuminated cartouches.
/// - Centered Basmalah line with authentic font scaling.
/// - Traditional footer with Quranic page numerals: ﴿ ٤٥ ﴾.
class QcfMushafPageRenderer extends StatefulWidget {
  final QcfPageModel pageModel;
  final bool isNightMode;
  final MushafThemeMode themeMode;
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
    this.isNightMode = false,
    this.themeMode = MushafThemeMode.ivory,
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

  // 1. Royal Ivory Theme (عاجي ملكي) - Classic Medina Parchment
  static const Color ivoryPaper = Color(0xFFFAF6EE);
  static const Color ivoryText = Color(0xFF231F1B);
  static const Color ivorySecondary = Color(0xFF7A6B5B);
  static const Color ivoryGold = Color(0xFFB38938);
  static const Color ivoryFrame = Color(0xFFC49A45);

  // 2. Antique Sepia Theme (بيج تراثي) - Warm Eye-Comfort Parchment
  static const Color sepiaPaper = Color(0xFFF3EBD9);
  static const Color sepiaText = Color(0xFF2C2218);
  static const Color sepiaSecondary = Color(0xFF73604C);
  static const Color sepiaGold = Color(0xFFA67C2E);
  static const Color sepiaFrame = Color(0xFFB88E3E);

  // 3. Quiet Night Theme (ليلي هادئ) - Deep OLED Slate
  static const Color nightPaper = Color(0xFF121714);
  static const Color nightText = Color(0xFFECE8DF);
  static const Color nightSecondary = Color(0xFFA3988A);
  static const Color nightGold = Color(0xFFD4AF37);
  static const Color nightFrame = Color(0xFF8A7135);

  // Backward compatibility aliases
  static const Color paperBg = ivoryPaper;
  static const Color textDark = ivoryText;
  static const Color secondaryText = ivorySecondary;
  static const Color goldAccent = ivoryGold;
  static const Color frameGold = ivoryFrame;

  @override
  State<QcfMushafPageRenderer> createState() => _QcfMushafPageRendererState();
}

class _QcfMushafPageRendererState extends State<QcfMushafPageRenderer> {
  @override
  void initState() {
    super.initState();
    QcfFontService.instance.fontLoadedNotifier.addListener(_onFontLoaded);
    _ensureFont();
  }

  @override
  void didUpdateWidget(QcfMushafPageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageModel.page != widget.pageModel.page) {
      _ensureFont();
    }
  }

  @override
  void dispose() {
    QcfFontService.instance.fontLoadedNotifier.removeListener(_onFontLoaded);
    super.dispose();
  }

  void _onFontLoaded() {
    if (QcfFontService.instance.isFontLoaded(widget.pageModel.page)) {
      if (mounted) setState(() {});
    }
  }

  void _ensureFont() {
    QcfFontService.instance.ensurePageFont(widget.pageModel.page);
  }

  @override
  Widget build(BuildContext context) {
    final pageNum = widget.pageModel.page;
    final isQcfLoaded = QcfFontService.instance.isFontLoaded(pageNum);
    final effectiveTheme = widget.isNightMode ? MushafThemeMode.night : widget.themeMode;

    final Color bgPaper;
    final Color textDarkColor;
    final Color secondary;
    final Color gold;
    final Color frameColor;

    switch (effectiveTheme) {
      case MushafThemeMode.ivory:
        bgPaper = QcfMushafPageRenderer.ivoryPaper;
        textDarkColor = QcfMushafPageRenderer.ivoryText;
        secondary = QcfMushafPageRenderer.ivorySecondary;
        gold = QcfMushafPageRenderer.ivoryGold;
        frameColor = QcfMushafPageRenderer.ivoryFrame;
        break;
      case MushafThemeMode.sepia:
        bgPaper = QcfMushafPageRenderer.sepiaPaper;
        textDarkColor = QcfMushafPageRenderer.sepiaText;
        secondary = QcfMushafPageRenderer.sepiaSecondary;
        gold = QcfMushafPageRenderer.sepiaGold;
        frameColor = QcfMushafPageRenderer.sepiaFrame;
        break;
      case MushafThemeMode.night:
        bgPaper = QcfMushafPageRenderer.nightPaper;
        textDarkColor = QcfMushafPageRenderer.nightText;
        secondary = QcfMushafPageRenderer.nightSecondary;
        gold = QcfMushafPageRenderer.nightGold;
        frameColor = QcfMushafPageRenderer.nightFrame;
        break;
    }

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;

          // Frame dimensions with authentic proportions
          final double hMargin = (viewportWidth * 0.032).clamp(6.0, 16.0);
          final double vMargin = (viewportHeight * 0.016).clamp(4.0, 12.0);
          final double frameWidth = viewportWidth - (hMargin * 2);
          final double frameHeight = viewportHeight - (vMargin * 2);

          const double headerHeight = 28.0;
          const double footerHeight = 26.0;
          final double innerPadH = (frameWidth * 0.025).clamp(6.0, 12.0);
          final double readingWidth = frameWidth - (innerPadH * 2) - 8.0; // padding inside frame
          final double availableLinesHeight = frameHeight - headerHeight - footerHeight - 6.0;

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
                  // 1. Medina Mushaf Frame & Content Canvas
                  Center(
                    child: SizedBox(
                      width: frameWidth,
                      height: frameHeight,
                      child: CustomPaint(
                        painter: _MushafPageFramePainter(
                          goldColor: frameColor,
                          headerHeight: headerHeight,
                          footerHeight: footerHeight,
                          isOpeningPage: pageNum <= 2,
                        ),
                        child: Column(
                          children: [
                            // ── Top Header Bar ──
                            SizedBox(
                              height: headerHeight,
                              child: _buildHeaderBar(pageNum, gold, secondary),
                            ),

                            // ── The 15 Quran Lines ──
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: innerPadH + 4.0),
                                child: _buildLinesCanvas(
                                  pageNum,
                                  textDarkColor,
                                  secondary,
                                  gold,
                                  readingWidth,
                                  availableLinesHeight,
                                  isQcfLoaded,
                                ),
                              ),
                            ),

                            // ── Bottom Page Num Footer ──
                            SizedBox(
                              height: footerHeight,
                              child: _buildFooterBar(pageNum, gold, textDarkColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Tap Left Edge -> Previous Page
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 36,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: widget.onPreviousPage,
                    ),
                  ),

                  // 3. Tap Right Edge -> Next Page
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 36,
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
      ),
    );
  }

  /// Top Header Bar of the Mushaf Page (Surah title on one side, Juz on the other)
  Widget _buildHeaderBar(int pageNum, Color gold, Color secondary) {
    if (pageNum <= 2) {
      // Opening pages (Al-Fatihah / Al-Baqarah 1-5) have special illuminated headers
      return Center(
        child: Text(
          pageNum == 1 ? 'سُورَةُ ٱلْفَاتِحَةِ' : 'سُورَةُ ٱلْبَقَرَةِ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: gold,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    final isEven = pageNum % 2 == 0;
    final leftText = isEven ? 'سُورَةُ ${widget.surahName}' : 'ٱلْجُزْءُ ${toArabicDigits(widget.juz)}';
    final rightText = isEven ? 'ٱلْجُزْءُ ${toArabicDigits(widget.juz)}' : 'سُورَةُ ${widget.surahName}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Right text
          Text(
            rightText,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: secondary,
            ),
          ),
          // Center ornamental flourish
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 14, height: 0.8, color: gold.withValues(alpha: 0.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.circle, size: 4.5, color: gold),
              ),
              Container(width: 14, height: 0.8, color: gold.withValues(alpha: 0.5)),
            ],
          ),
          // Left text
          Text(
            leftText,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Footer Bar with Quranic Page Number: ﴿ ٤٥ ﴾
  Widget _buildFooterBar(int pageNum, Color gold, Color textColor) {
    return Center(
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '﴿  ',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13.0,
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: toArabicDigits(pageNum),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13.0,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '  ﴾',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13.0,
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
    bool isQcfLoaded,
  ) {
    final lines = widget.pageModel.lines;
    final fontFamily = isQcfLoaded ? QcfFontService.fontFamilyForPage(pageNum) : 'AmiriQuran';

    // ── PAGE 1: Al-Fatihah ──
    if (pageNum == 1) {
      final p1SlotHeight = (availableLinesHeight / 9.5).clamp(42.0, 52.0);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: SizedBox(
                  height: p1SlotHeight,
                  child: _buildLine(
                    line: line,
                    pageNum: pageNum,
                    textDark: textDark,
                    secondary: secondary,
                    gold: gold,
                    readingWidth: readingWidth,
                    slotHeight: p1SlotHeight,
                    isQcfLoaded: isQcfLoaded,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // ── PAGE 2: Al-Baqarah 1-5 ──
    if (pageNum == 2) {
      final p2SlotHeight = (availableLinesHeight / 10.5).clamp(42.0, 52.0);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: SizedBox(
                  height: p2SlotHeight,
                  child: _buildLine(
                    line: line,
                    pageNum: pageNum,
                    textDark: textDark,
                    secondary: secondary,
                    gold: gold,
                    readingWidth: readingWidth,
                    slotHeight: p2SlotHeight,
                    isQcfLoaded: isQcfLoaded,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // ── PAGES 3-604: Standard 15-Line Pages ──
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
              line: line,
              pageNum: pageNum,
              textDark: textDark,
              secondary: secondary,
              gold: gold,
              readingWidth: readingWidth,
              slotHeight: lineSlotHeight,
              isQcfLoaded: isQcfLoaded,
              fontFamily: fontFamily,
            ),
          ),
      ],
    );
  }

  /// Dispatches line rendering based on its type.
  Widget _buildLine({
    required QcfLineModel line,
    required int pageNum,
    required Color textDark,
    required Color secondary,
    required Color gold,
    required double readingWidth,
    required double slotHeight,
    required bool isQcfLoaded,
    required String fontFamily,
  }) {
    if (line.isSurahHeader) {
      return _buildSurahHeaderBanner(line, textDark, gold, readingWidth, slotHeight);
    }
    if (line.isBasmala) {
      return _buildBasmalaLine(line, pageNum, textDark, readingWidth, slotHeight, isQcfLoaded);
    }
    return _buildTextLine(
      line: line,
      pageNum: pageNum,
      textDark: textDark,
      gold: gold,
      readingWidth: readingWidth,
      slotHeight: slotHeight,
      isQcfLoaded: isQcfLoaded,
      fontFamily: fontFamily,
    );
  }

  /// Calligraphic Surah Header Banner with traditional Islamic framing.
  Widget _buildSurahHeaderBanner(
    QcfLineModel line,
    Color textColor,
    Color gold,
    double readingWidth,
    double slotHeight,
  ) {
    final effectiveTheme = widget.isNightMode ? MushafThemeMode.night : widget.themeMode;
    final bgBanner = effectiveTheme == MushafThemeMode.night
        ? const Color(0xFF1E2420)
        : (effectiveTheme == MushafThemeMode.sepia ? const Color(0xFFEFE5CF) : const Color(0xFFFBF8F1));
    final borderCol = gold.withValues(alpha: effectiveTheme == MushafThemeMode.night ? 0.7 : 0.85);
    final surahTitle = line.text ?? 'سُورَةُ ${widget.surahName}';
    final bannerHeight = (slotHeight * 0.84).clamp(32.0, 42.0);

    return Center(
      child: Container(
        height: bannerHeight,
        width: readingWidth,
        margin: const EdgeInsets.symmetric(vertical: 1.0),
        decoration: BoxDecoration(
          color: bgBanner,
          border: Border.all(color: borderCol, width: 1.1),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
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
    int pageNum,
    Color textColor,
    double readingWidth,
    double slotHeight,
    bool isQcfLoaded,
  ) {
    final useQcf = isQcfLoaded && line.qpcV2 != null && line.qpcV2!.isNotEmpty;
    final glyphText = useQcf ? line.qpcV2! : 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
    final font = useQcf ? QcfFontService.fontFamilyForPage(pageNum) : 'AmiriQuran';

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
              fontFamily: font,
              fontFamilyFallback: const ['AmiriQuran', 'Amiri', 'serif'],
              fontSize: (slotHeight * 0.58).clamp(22.0, 26.0),
              height: 1.3,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Deterministic Text Line with full-width line justification
  /// matching the physical Medina Mushaf block layout.
  Widget _buildTextLine({
    required QcfLineModel line,
    required int pageNum,
    required Color textDark,
    required Color gold,
    required double readingWidth,
    required double slotHeight,
    required bool isQcfLoaded,
    required String fontFamily,
  }) {
    if (line.words.isEmpty) {
      return const SizedBox.shrink();
    }

    final double wordFontSize = (pageNum == 1)
        ? 26.0
        : ((pageNum == 2)
            ? 25.0
            : ((readingWidth / 353.0) * 22.0).clamp(18.0, 26.0));

    final bool isPage1 = pageNum == 1;
    final bool isLastLineOfPage2 = pageNum == 2 && line.line == 8;
    final bool isShortFinalLine = (line.words.length < 5 && line.line == 15);
    final bool isCentered = isPage1 || isLastLineOfPage2 || isShortFinalLine;

    final spans = <InlineSpan>[];
    for (int i = 0; i < line.words.length; i++) {
      final word = line.words[i];
      spans.add(_buildWordSpan(
        word: word,
        fontFamily: fontFamily,
        wordFontSize: wordFontSize,
        isLastWord: i == line.words.length - 1,
        goldColor: gold,
        isQcfLoaded: isQcfLoaded,
      ));
    }

    // Natural width measurement for full-width line distribution
    double calculatedWordSpacing = 0.0;
    if (!isCentered && line.words.length > 1) {
      try {
        final rosetteSize = (wordFontSize * 0.95).clamp(19.0, 25.0) + 3.0;
        final placeholders = <PlaceholderDimensions>[];
        for (final span in spans) {
          _collectPlaceholderDimensions(span, placeholders, rosetteSize);
        }

        final textPainter = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.rtl,
        );
        if (placeholders.isNotEmpty) {
          textPainter.setPlaceholderDimensions(placeholders);
        }
        textPainter.layout();

        final extraSpace = readingWidth - textPainter.width;
        if (extraSpace > 0) {
          calculatedWordSpacing = (extraSpace / (line.words.length - 1)).clamp(0.0, 14.0);
        }
      } catch (_) {
        calculatedWordSpacing = 0.0;
      }
    }

    return Center(
      child: SizedBox(
        width: readingWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  wordSpacing: calculatedWordSpacing > 0 ? calculatedWordSpacing : null,
                ),
                children: spans,
              ),
              textAlign: isCentered ? TextAlign.center : TextAlign.justify,
              textDirection: TextDirection.rtl,
              softWrap: false,
            ),
          ),
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
    required bool isQcfLoaded,
  }) {
    final surahId = word.surahId ?? 1;
    final ayahId = word.ayahId ?? 1;
    final ayahKey = '$surahId:$ayahId';

    final isSelected = widget.selectedAyat.containsKey(ayahKey);
    final isHighlighted = widget.highlightedAyahId == ayahId &&
        (widget.highlightedSurahId == null || widget.highlightedSurahId == surahId);
    final anyHighlighted = widget.highlightedAyahId != null;

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

    final effectiveTheme = widget.isNightMode ? MushafThemeMode.night : widget.themeMode;
    final Color themeDefaultText;
    switch (effectiveTheme) {
      case MushafThemeMode.ivory:
        themeDefaultText = QcfMushafPageRenderer.ivoryText;
        break;
      case MushafThemeMode.sepia:
        themeDefaultText = QcfMushafPageRenderer.sepiaText;
        break;
      case MushafThemeMode.night:
        themeDefaultText = QcfMushafPageRenderer.nightText;
        break;
    }

    Color wordTextColor;
    if (isSelected) {
      wordTextColor = effectiveTheme == MushafThemeMode.night ? AppColors.accentGoldLight : const Color(0xFF8C5D00);
    } else if (isHighlighted) {
      wordTextColor = effectiveTheme == MushafThemeMode.night ? const Color(0xFFFDE68A) : const Color(0xFF78350F);
    } else if (anyHighlighted) {
      wordTextColor = themeDefaultText.withValues(alpha: effectiveTheme == MushafThemeMode.night ? 0.55 : 0.65);
    } else {
      wordTextColor = themeDefaultText;
    }

    Color? wordBgColor;
    if (isSelected) {
      wordBgColor = AppColors.accentGold.withValues(alpha: 0.28);
    } else if (isHighlighted) {
      wordBgColor = AppColors.accentGold.withValues(alpha: effectiveTheme == MushafThemeMode.night ? 0.32 : 0.20);
    } else if (isBookmarked) {
      wordBgColor = bookmarkColor.withValues(alpha: 0.12);
    }

    final suffix = isLastWord ? '' : ' ';

    // ── QCF Mode: High-Fidelity Ligatures ──
    if (isQcfLoaded && word.qpcV2.isNotEmpty) {
      if (word.isAyahEnd) {
        final glyphs = word.qpcV2.characters.toList();
        if (glyphs.length >= 2) {
          final numberGlyphs = glyphs.sublist(0, glyphs.length - 1).join();
          final markerGlyph = glyphs.last;
          return TextSpan(
            children: [
              TextSpan(
                text: numberGlyphs,
                recognizer: AyahGestureRecognizer()
                  ..onLongPress = () {
                    widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
                  },
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: wordFontSize,
                  fontWeight: FontWeight.w400,
                  color: wordTextColor,
                  backgroundColor: wordBgColor,
                  height: 1.0,
                ),
              ),
              TextSpan(
                text: '$markerGlyph$suffix',
                recognizer: AyahGestureRecognizer()
                  ..onLongPress = () {
                    widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
                  },
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: wordFontSize,
                  fontWeight: FontWeight.w400,
                  color: goldColor,
                  backgroundColor: wordBgColor,
                  height: 1.0,
                ),
              ),
            ],
          );
        }
      }

      return TextSpan(
        text: '${word.qpcV2}$suffix',
        recognizer: AyahGestureRecognizer()
          ..onLongPress = () {
            widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
          },
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: wordFontSize,
          fontWeight: FontWeight.w400,
          color: wordTextColor,
          backgroundColor: wordBgColor,
          height: 1.0,
        ),
      );
    }

    // ── Fallback Mode: AmiriQuran Unicode Text ──
    if (word.isAyahEnd) {
      final cleanWord = word.word.replaceAll(RegExp(r'[٠-٩0-9]+'), '').trim();
      return TextSpan(
        children: [
          if (cleanWord.isNotEmpty)
            TextSpan(
              text: '$cleanWord ',
              recognizer: AyahGestureRecognizer()
                ..onLongPress = () {
                  widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
                },
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: wordFontSize,
                fontWeight: FontWeight.w400,
                color: wordTextColor,
                backgroundColor: wordBgColor,
                height: 1.25,
              ),
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            style: TextStyle(
              backgroundColor: wordBgColor,
            ),
            child: GestureDetector(
              onLongPress: () => widget.onAyahLongPress(surahId: surahId, ayahId: ayahId),
              child: Container(
                color: wordBgColor,
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: SizedBox(
                  width: (wordFontSize * 0.95).clamp(19.0, 25.0),
                  height: (wordFontSize * 0.95).clamp(19.0, 25.0),
                  child: AyahRosette(
                    ayahNumber: ayahId,
                    borderColor: goldColor,
                    textColor: wordTextColor,
                    highlightBgColor: wordBgColor,
                    size: (wordFontSize * 0.95).clamp(19.0, 25.0),
                  ),
                ),
              ),
            ),
          ),
          TextSpan(text: suffix),
        ],
      );
    }

    return TextSpan(
      text: '${word.word}$suffix',
      recognizer: AyahGestureRecognizer()
        ..onLongPress = () {
          widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
        },
      style: TextStyle(
        fontFamily: 'AmiriQuran',
        fontSize: wordFontSize,
        fontWeight: FontWeight.w400,
        color: wordTextColor,
        backgroundColor: wordBgColor,
        height: 1.25,
      ),
    );
  }

  static void _collectPlaceholderDimensions(
    InlineSpan span,
    List<PlaceholderDimensions> dimensions,
    double defaultSize,
  ) {
    if (span is WidgetSpan) {
      dimensions.add(PlaceholderDimensions(
        size: Size(defaultSize, defaultSize),
        alignment: span.alignment,
        baseline: span.baseline,
      ));
    } else if (span is TextSpan && span.children != null) {
      for (final child in span.children!) {
        _collectPlaceholderDimensions(child, dimensions, defaultSize);
      }
    }
  }
}

/// CustomPainter that renders the authentic double gold Medina Mushaf frame
/// with corner flourishes and header/footer section dividers.
class _MushafPageFramePainter extends CustomPainter {
  final Color goldColor;
  final double headerHeight;
  final double footerHeight;
  final bool isOpeningPage;

  const _MushafPageFramePainter({
    required this.goldColor,
    required this.headerHeight,
    required this.footerHeight,
    required this.isOpeningPage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerStroke = Paint()
      ..color = goldColor.withValues(alpha: 0.65)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final innerStroke = Paint()
      ..color = goldColor.withValues(alpha: 0.85)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    const outerGap = 1.5;
    const innerGap = 4.5;
    final w = size.width;
    final h = size.height;

    // 1. Outer Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(outerGap, outerGap, w - (outerGap * 2), h - (outerGap * 2)),
        const Radius.circular(3),
      ),
      outerStroke,
    );

    // 2. Inner Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(innerGap, innerGap, w - (innerGap * 2), h - (innerGap * 2)),
        const Radius.circular(2),
      ),
      innerStroke,
    );

    // 3. Corner Ornamental Diamonds
    _drawCornerDiamond(canvas, fillPaint, innerGap + 3.0, innerGap + 3.0);
    _drawCornerDiamond(canvas, fillPaint, w - innerGap - 3.0, innerGap + 3.0);
    _drawCornerDiamond(canvas, fillPaint, innerGap + 3.0, h - innerGap - 3.0);
    _drawCornerDiamond(canvas, fillPaint, w - innerGap - 3.0, h - innerGap - 3.0);

    // 4. Horizontal Dividers for Header & Footer
    final dividerPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.40)
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    // Header divider line
    canvas.drawLine(
      Offset(innerGap, headerHeight),
      Offset(w - innerGap, headerHeight),
      dividerPaint,
    );

    // Footer divider line
    final footerY = h - footerHeight;
    canvas.drawLine(
      Offset(innerGap, footerY),
      Offset(w - innerGap, footerY),
      dividerPaint,
    );
  }

  void _drawCornerDiamond(Canvas canvas, Paint paint, double cx, double cy) {
    const r = 2.2;
    final path = Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx + r, cy)
      ..lineTo(cx, cy + r)
      ..lineTo(cx - r, cy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MushafPageFramePainter old) {
    return old.goldColor != goldColor ||
        old.headerHeight != headerHeight ||
        old.footerHeight != footerHeight ||
        old.isOpeningPage != isOpeningPage;
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
