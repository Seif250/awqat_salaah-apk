import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../data/models/ayah_model.dart';
import 'quran_share_layout_engine.dart';

export 'quran_share_layout_engine.dart' show QuranShareLayoutEngine, QuranShareLayoutMode;

/// Layout specification and measurement data for a single Quran share image page.
class SharePageData {
  final int pageIndex; // 1-based index (e.g. 1)
  final int totalPages; // Total pages count (e.g. 2)
  final List<AyahModel> verses;
  final int startAyah;
  final int endAyah;
  final String surahName;
  final double canvasWidth;
  final double canvasHeight;
  final double measuredTextHeight;
  final double contentWidth;
  final double fontSize;
  final double lineHeight;
  final double rosetteSize;
  final QuranShareLayoutMode layoutMode;
  final List<List<AyahModel>>? pairedRows;
  final double headerToTextGap;
  final double textToFooterGap;
  final double topPadding;
  final double bottomPadding;

  const SharePageData({
    required this.pageIndex,
    required this.totalPages,
    required this.verses,
    required this.startAyah,
    required this.endAyah,
    required this.surahName,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.measuredTextHeight,
    required this.contentWidth,
    required this.fontSize,
    required this.lineHeight,
    this.rosetteSize = 44.0,
    this.layoutMode = QuranShareLayoutMode.continuous,
    this.pairedRows,
    this.headerToTextGap = 36.0,
    this.textToFooterGap = 36.0,
    this.topPadding = 90.0,
    this.bottomPadding = 80.0,
  });

  bool get isMultiPage => totalPages > 1;

  double get aspectRatio => canvasWidth / canvasHeight;
}

/// Result of layout calculation containing one or more pages.
class ShareLayoutResult {
  final List<SharePageData> pages;

  const ShareLayoutResult({required this.pages});

  int get totalPages => pages.length;
  SharePageData get firstPage => pages.first;
}

/// Pure calculation engine for the Quran share image canvas.
///
/// Features:
/// - Resolution independent (1080px base canvas).
/// - 4:5 portrait aspect ratio (1080 × 1350) for standard selections.
/// - Dynamic height extension for medium-long selections (1080 × 1500, 1650, etc.).
/// - Multi-page splitting when actual measured height exceeds [kMaxSinglePageHeight].
/// - Measurement uses exact same typography scale, line-height, and rosette dimensions.
class ShareLayoutCalculator {
  // ── Source of truth canvas dimensions ──────────────────────────────────────
  static const double kCanvasWidth = 1080.0;
  static const double kBaseAspectRatio = 4.0 / 5.0; // 0.8
  static const double kMinCanvasHeight = 1350.0; // 1080 * 1.25 (4:5)
  static const double kMaxSinglePageHeight = 1920.0; // Safe upper bound (9:16)

  // ── Layout padding & margins ──────────────────────────────────────────────
  static const double kContentWidth = 890.0; // 82.4% of 1080
  static const double kHorizontalPadding = (kCanvasWidth - kContentWidth) / 2.0; // 95.0
  static const double kTopPadding = 90.0;
  static const double kHeaderHeight = 110.0;
  static const double kHeaderToTextGap = 36.0;
  static const double kTextToFooterGap = 36.0;
  static const double kFooterHeight = 80.0;
  static const double kBottomPadding = 80.0;

  /// Fixed non-content chrome height (header, footer, gaps, padding)
  static const double kChromeHeight =
      kTopPadding + kHeaderHeight + kHeaderToTextGap + kTextToFooterGap + kFooterHeight + kBottomPadding; // 432.0

  // ── Typography defaults at 1080px canvas scale ────────────────────────────
  static const double kDefaultFontSize = 38.0;
  static const double kDefaultLineHeight = 2.2;
  static const double kRosetteSize = 46.0;

  /// Computes the exact layout and pages for the given verses.
  static ShareLayoutResult calculate({
    required String surahName,
    required List<AyahModel> verses,
    double fontSize = kDefaultFontSize,
    double lineHeight = kDefaultLineHeight,
    double rosetteSize = kRosetteSize,
  }) {
    if (verses.isEmpty) {
      return ShareLayoutResult(
        pages: [
          SharePageData(
            pageIndex: 1,
            totalPages: 1,
            verses: const [],
            startAyah: 1,
            endAyah: 1,
            surahName: surahName,
            canvasWidth: kCanvasWidth,
            canvasHeight: kMinCanvasHeight,
            measuredTextHeight: 0,
            contentWidth: kContentWidth,
            fontSize: fontSize,
            lineHeight: lineHeight,
          ),
        ],
      );
    }

    // 1. First measure all verses together as a single block
    final totalMeasuredHeight = measureVersesHeight(
      verses: verses,
      fontSize: fontSize,
      lineHeight: lineHeight,
      rosetteSize: rosetteSize,
      maxWidth: kContentWidth,
    );

    final totalRequiredHeight = kChromeHeight + totalMeasuredHeight;

    // 2. If it fits within the maximum single page height, keep as 1 page
    if (totalRequiredHeight <= kMaxSinglePageHeight) {
      final canvasHeight = math.max(kMinCanvasHeight, totalRequiredHeight);
      return ShareLayoutResult(
        pages: [
          SharePageData(
            pageIndex: 1,
            totalPages: 1,
            verses: verses,
            startAyah: verses.first.id,
            endAyah: verses.last.id,
            surahName: surahName,
            canvasWidth: kCanvasWidth,
            canvasHeight: canvasHeight,
            measuredTextHeight: totalMeasuredHeight,
            contentWidth: kContentWidth,
            fontSize: fontSize,
            lineHeight: lineHeight,
          ),
        ],
      );
    }

    // 3. Otherwise, split into multiple pages based on actual measured content
    final pagesVerses = <List<AyahModel>>[];
    var currentBatch = <AyahModel>[];

    final maxTextHeightPerPage = kMaxSinglePageHeight - kChromeHeight;

    for (final verse in verses) {
      final candidateBatch = [...currentBatch, verse];
      final candidateHeight = measureVersesHeight(
        verses: candidateBatch,
        fontSize: fontSize,
        lineHeight: lineHeight,
        rosetteSize: rosetteSize,
        maxWidth: kContentWidth,
      );

      if (candidateHeight <= maxTextHeightPerPage || currentBatch.isEmpty) {
        currentBatch.add(verse);
      } else {
        // Current batch is full, start a new page
        pagesVerses.add(List<AyahModel>.unmodifiable(currentBatch));
        currentBatch = [verse];
      }
    }

    if (currentBatch.isNotEmpty) {
      pagesVerses.add(List<AyahModel>.unmodifiable(currentBatch));
    }

    final totalPagesCount = pagesVerses.length;
    final pagesData = <SharePageData>[];

    for (int i = 0; i < totalPagesCount; i++) {
      final batch = pagesVerses[i];
      final batchHeight = measureVersesHeight(
        verses: batch,
        fontSize: fontSize,
        lineHeight: lineHeight,
        rosetteSize: rosetteSize,
        maxWidth: kContentWidth,
      );
      final pageHeight = math.max(kMinCanvasHeight, kChromeHeight + batchHeight);

      pagesData.add(
        SharePageData(
          pageIndex: i + 1,
          totalPages: totalPagesCount,
          verses: batch,
          startAyah: batch.first.id,
          endAyah: batch.last.id,
          surahName: surahName,
          canvasWidth: kCanvasWidth,
          canvasHeight: pageHeight,
          measuredTextHeight: batchHeight,
          contentWidth: kContentWidth,
          fontSize: fontSize,
          lineHeight: lineHeight,
        ),
      );
    }

    return ShareLayoutResult(pages: pagesData);
  }

  /// Accurately measures the height of a list of verses rendered as a continuous text block
  /// with embedded inline rosette placeholders.
  static double measureVersesHeight({
    required List<AyahModel> verses,
    required double fontSize,
    required double lineHeight,
    required double rosetteSize,
    required double maxWidth,
  }) {
    if (verses.isEmpty) return 0.0;

    final spans = <InlineSpan>[];
    for (final ayah in verses) {
      spans.add(
        TextSpan(
          text: '${ayah.text} ',
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: fontSize,
            height: lineHeight,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      spans.add(
        WidgetSpan(
          alignment: ui.PlaceholderAlignment.middle,
          child: SizedBox(
            width: rosetteSize,
            height: rosetteSize,
          ),
        ),
      );
      spans.add(const TextSpan(text: ' '));
    }

    final textPainter = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );

    textPainter.setPlaceholderDimensions(
      List.filled(
        verses.length,
        PlaceholderDimensions(
          size: Size(rosetteSize + 8.0, rosetteSize),
          alignment: PlaceholderAlignment.middle,
        ),
      ),
    );

    textPainter.layout(minWidth: maxWidth, maxWidth: maxWidth);
    final height = textPainter.height;
    textPainter.dispose();

    return height;
  }
}
