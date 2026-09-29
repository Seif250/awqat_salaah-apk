import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../data/models/ayah_model.dart';
import 'share_layout_calculator.dart';

/// Layout mode selected by the layout engine.
enum QuranShareLayoutMode {
  continuous,
  pairedCompact,
  compactContinuous,
  reducedSpacing,
}

/// Candidate solution evaluated by [QuranShareLayoutEngine].
class LayoutCandidate {
  final QuranShareLayoutMode mode;
  final double fontSize;
  final double lineHeight;
  final double rosetteSize;
  final double contentWidth;
  final double chromeHeight;
  final double topPadding;
  final double bottomPadding;
  final double headerToTextGap;
  final double textToFooterGap;
  final double measuredTextHeight;
  final double totalRequiredHeight;
  final List<List<AyahModel>>? pairedRows;
  final double score;

  const LayoutCandidate({
    required this.mode,
    required this.fontSize,
    required this.lineHeight,
    required this.rosetteSize,
    required this.contentWidth,
    required this.chromeHeight,
    required this.topPadding,
    required this.bottomPadding,
    required this.headerToTextGap,
    required this.textToFooterGap,
    required this.measuredTextHeight,
    required this.totalRequiredHeight,
    this.pairedRows,
    required this.score,
  });
}

/// Intelligent, resolution-independent layout engine for Quran share images.
///
/// Design goals:
/// 1. Primary target is always 1080 × 1350 (4:5 portrait aspect ratio).
/// 2. Compares multiple layout candidates:
///    - Continuous Flow
///    - Paired Compact (optional for short, balanced verses)
///    - Compact Continuous
///    - Reduced-Spacing Continuous
/// 3. Scores candidates using an aesthetic & readability formula.
/// 4. Controlled height extension up to 1080 × 1440 ONLY for an exceptional single long Ayah.
/// 5. For multi-Ayah selections, splits at complete Ayah boundaries without vertical distortion.
/// 6. Exactly mirrors final rendering typography (UthmanicHafs + AyahRosette placeholder).
class QuranShareLayoutEngine {
  // ── Source of truth canvas dimensions ──────────────────────────────────────
  static const double kCanvasWidth = 1080.0;
  static const double kBaseCanvasHeight = 1350.0; // 4:5 aspect ratio
  static const double kMaxSingleAyahHeight = 1440.0; // Exceptional maximum for single long Ayah
  static const double kMaxSinglePageHeight = 1440.0;

  // ── Content widths ─────────────────────────────────────────────────────────
  static const double kStandardContentWidth = 890.0;
  static const double kCompactContentWidth = 910.0;

  // ── Configurable font size ladder ──────────────────────────────────────────
  static const double kMaxFontSize = 44.0;
  static const double kPreferredFontSize = 42.0;
  static const double kNormalFontSize = 38.0;
  static const double kCompactFontSize = 34.0;
  static const double kMinFontSize = 28.0;

  static const List<double> kFontSizeLadder = [
    44.0,
    42.0,
    40.0,
    38.0,
    36.0,
    34.0,
    32.0,
    30.0,
    28.0,
  ];

  // ── Standard chrome spacing ────────────────────────────────────────────────
  static const double kStandardTopPadding = 90.0;
  static const double kStandardBottomPadding = 80.0;
  static const double kStandardHeaderHeight = 110.0;
  static const double kStandardFooterHeight = 80.0;
  static const double kStandardHeaderToTextGap = 36.0;
  static const double kStandardTextToFooterGap = 36.0;

  static const double kStandardChromeHeight = kStandardTopPadding +
      kStandardHeaderHeight +
      kStandardHeaderToTextGap +
      kStandardTextToFooterGap +
      kStandardFooterHeight +
      kStandardBottomPadding; // 432.0

  // ── Tight chrome spacing ───────────────────────────────────────────────────
  static const double kTightTopPadding = 75.0;
  static const double kTightBottomPadding = 75.0;
  static const double kTightHeaderToTextGap = 24.0;
  static const double kTightTextToFooterGap = 24.0;

  static const double kTightChromeHeight = kTightTopPadding +
      kStandardHeaderHeight +
      kTightHeaderToTextGap +
      kTightTextToFooterGap +
      kStandardFooterHeight +
      kTightBottomPadding; // 384.0

  /// Computes the optimal layout for the given verses and surah name.
  static ShareLayoutResult calculate({
    required String surahName,
    required List<AyahModel> verses,
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
            canvasHeight: kBaseCanvasHeight,
            measuredTextHeight: 0,
            contentWidth: kStandardContentWidth,
            fontSize: kNormalFontSize,
            lineHeight: 2.2,
            rosetteSize: 44.0,
            layoutMode: QuranShareLayoutMode.continuous,
          ),
        ],
      );
    }

    // 1. Try to fit all verses into a single page (preferring 1080 × 1350)
    final singlePageCandidate = _findBestCandidate(verses, allowExtension: verses.length == 1);

    if (singlePageCandidate != null) {
      final canvasHeight = singlePageCandidate.totalRequiredHeight <= kBaseCanvasHeight
          ? kBaseCanvasHeight
          : math.min(kMaxSingleAyahHeight, singlePageCandidate.totalRequiredHeight);

      return ShareLayoutResult(
        pages: [
          _createPageData(
            pageIndex: 1,
            totalPages: 1,
            verses: verses,
            surahName: surahName,
            candidate: singlePageCandidate,
            canvasHeight: canvasHeight,
          ),
        ],
      );
    }

    // 2. If it does not fit as a single page (and is not an exceptional single long Ayah),
    // split at complete Ayah boundaries evenly across multiple pages.
    return _splitAndCalculatePages(surahName: surahName, verses: verses);
  }

  /// Generates and scores candidates for a single page, returning the best fit.
  static LayoutCandidate? _findBestCandidate(
    List<AyahModel> verses, {
    required bool allowExtension,
  }) {
    final validCandidates = <LayoutCandidate>[];

    // Candidate A: Continuous Flow (Standard)
    for (final font in kFontSizeLadder) {
      final candidate = _evaluateContinuous(
        verses: verses,
        fontSize: font,
        lineHeight: 2.2,
        contentWidth: kStandardContentWidth,
        chromeHeight: kStandardChromeHeight,
        topPadding: kStandardTopPadding,
        bottomPadding: kStandardBottomPadding,
        headerToTextGap: kStandardHeaderToTextGap,
        textToFooterGap: kStandardTextToFooterGap,
        mode: QuranShareLayoutMode.continuous,
      );
      if (candidate.totalRequiredHeight <= kBaseCanvasHeight) {
        validCandidates.add(candidate);
        break; // Found largest readable font that fits 1350px
      } else if (allowExtension && candidate.totalRequiredHeight <= kMaxSingleAyahHeight) {
        validCandidates.add(candidate);
      }
    }

    // Candidate B: Paired Compact (Evaluated if short, symmetric verses exist)
    if (verses.length >= 2 && verses.length <= 6 && _canAttemptPairedCompact(verses)) {
      for (final font in kFontSizeLadder.where((f) => f <= 40.0)) {
        final candidate = _evaluatePairedCompact(
          verses: verses,
          fontSize: font,
          lineHeight: 2.15,
          contentWidth: kStandardContentWidth,
          chromeHeight: kStandardChromeHeight,
        );
        if (candidate != null) {
          if (candidate.totalRequiredHeight <= kBaseCanvasHeight) {
            validCandidates.add(candidate);
            break;
          } else if (allowExtension && candidate.totalRequiredHeight <= kMaxSingleAyahHeight) {
            validCandidates.add(candidate);
          }
        }
      }
    }

    // Candidate C: Compact Continuous (Slightly wider content, slightly tighter line-height)
    for (final font in kFontSizeLadder.where((f) => f <= 40.0)) {
      final candidate = _evaluateContinuous(
        verses: verses,
        fontSize: font,
        lineHeight: 2.12,
        contentWidth: kCompactContentWidth,
        chromeHeight: kStandardChromeHeight,
        topPadding: kStandardTopPadding,
        bottomPadding: kStandardBottomPadding,
        headerToTextGap: kStandardHeaderToTextGap,
        textToFooterGap: kStandardTextToFooterGap,
        mode: QuranShareLayoutMode.compactContinuous,
      );
      if (candidate.totalRequiredHeight <= kBaseCanvasHeight) {
        validCandidates.add(candidate);
        break;
      } else if (allowExtension && candidate.totalRequiredHeight <= kMaxSingleAyahHeight) {
        validCandidates.add(candidate);
      }
    }

    // Candidate D: Reduced-Spacing Continuous (Tighter gaps)
    for (final font in kFontSizeLadder.where((f) => f <= 38.0)) {
      final candidate = _evaluateContinuous(
        verses: verses,
        fontSize: font,
        lineHeight: 2.08,
        contentWidth: kCompactContentWidth,
        chromeHeight: kTightChromeHeight,
        topPadding: kTightTopPadding,
        bottomPadding: kTightBottomPadding,
        headerToTextGap: kTightHeaderToTextGap,
        textToFooterGap: kTightTextToFooterGap,
        mode: QuranShareLayoutMode.reducedSpacing,
      );
      if (candidate.totalRequiredHeight <= kBaseCanvasHeight) {
        validCandidates.add(candidate);
        break;
      } else if (allowExtension && candidate.totalRequiredHeight <= kMaxSingleAyahHeight) {
        validCandidates.add(candidate);
      }
    }

    if (validCandidates.isEmpty) {
      return null;
    }

    // Sort by score descending
    validCandidates.sort((a, b) => b.score.compareTo(a.score));
    return validCandidates.first;
  }

  /// Evaluates continuous flow layout with exact text painter measurement.
  static LayoutCandidate _evaluateContinuous({
    required List<AyahModel> verses,
    required double fontSize,
    required double lineHeight,
    required double contentWidth,
    required double chromeHeight,
    required double topPadding,
    required double bottomPadding,
    required double headerToTextGap,
    required double textToFooterGap,
    required QuranShareLayoutMode mode,
  }) {
    final rosetteSize = _rosetteSizeFor(fontSize);
    final textHeight = measureContinuousTextHeight(
      verses: verses,
      fontSize: fontSize,
      lineHeight: lineHeight,
      rosetteSize: rosetteSize,
      maxWidth: contentWidth,
    );

    final totalHeight = chromeHeight + textHeight;
    final score = _calculateScore(
      totalHeight: totalHeight,
      fontSize: fontSize,
      measuredHeight: textHeight,
      availableHeight: kBaseCanvasHeight - chromeHeight,
      isPaired: false,
    );

    return LayoutCandidate(
      mode: mode,
      fontSize: fontSize,
      lineHeight: lineHeight,
      rosetteSize: rosetteSize,
      contentWidth: contentWidth,
      chromeHeight: chromeHeight,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      headerToTextGap: headerToTextGap,
      textToFooterGap: textToFooterGap,
      measuredTextHeight: textHeight,
      totalRequiredHeight: totalHeight,
      score: score,
    );
  }

  /// Checks if verses qualify for paired compact evaluation.
  static bool _canAttemptPairedCompact(List<AyahModel> verses) {
    // 1. All verses must be relatively short (e.g. <= 65 characters)
    for (final v in verses) {
      if (v.text.length > 65) return false;
    }

    // 2. Length symmetry: difference between max and min verse length <= 45%
    final lengths = verses.map((v) => v.text.length).toList();
    final minLen = lengths.reduce(math.min);
    final maxLen = lengths.reduce(math.max);
    if (minLen == 0 || (maxLen - minLen) / maxLen > 0.45) {
      return false;
    }

    return true;
  }

  /// Evaluates Paired Compact layout where adjacent short verses form balanced rows.
  static LayoutCandidate? _evaluatePairedCompact({
    required List<AyahModel> verses,
    required double fontSize,
    required double lineHeight,
    required double contentWidth,
    required double chromeHeight,
  }) {
    const double columnGap = 36.0;
    final halfWidth = (contentWidth - columnGap) / 2.0;
    final rosetteSize = _rosetteSizeFor(fontSize);

    // Group into paired rows
    final rows = <List<AyahModel>>[];
    var i = 0;
    while (i < verses.length) {
      if (i + 1 < verses.length) {
        rows.add([verses[i], verses[i + 1]]);
        i += 2;
      } else {
        rows.add([verses[i]]);
        i += 1;
      }
    }

    double totalTextHeight = 0.0;
    const double rowGap = 20.0;

    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      if (row.length == 2) {
        // Measure each cell
        final h1 = measureContinuousTextHeight(
          verses: [row[0]],
          fontSize: fontSize,
          lineHeight: lineHeight,
          rosetteSize: rosetteSize,
          maxWidth: halfWidth,
        );
        final h2 = measureContinuousTextHeight(
          verses: [row[1]],
          fontSize: fontSize,
          lineHeight: lineHeight,
          rosetteSize: rosetteSize,
          maxWidth: halfWidth,
        );

        // Safety check: each cell should not wrap more than 3 lines
        final maxLines = math.max(h1, h2) / (fontSize * lineHeight);
        if (maxLines > 3.2) {
          return null; // Reject: text too tall for paired column
        }

        totalTextHeight += math.max(h1, h2);
      } else {
        // Single centered Ayah
        final h = measureContinuousTextHeight(
          verses: [row[0]],
          fontSize: fontSize,
          lineHeight: lineHeight,
          rosetteSize: rosetteSize,
          maxWidth: contentWidth,
        );
        totalTextHeight += h;
      }

      if (r < rows.length - 1) {
        totalTextHeight += rowGap;
      }
    }

    final totalHeight = chromeHeight + totalTextHeight;
    final score = _calculateScore(
      totalHeight: totalHeight,
      fontSize: fontSize,
      measuredHeight: totalTextHeight,
      availableHeight: kBaseCanvasHeight - chromeHeight,
      isPaired: true,
    );

    return LayoutCandidate(
      mode: QuranShareLayoutMode.pairedCompact,
      fontSize: fontSize,
      lineHeight: lineHeight,
      rosetteSize: rosetteSize,
      contentWidth: contentWidth,
      chromeHeight: chromeHeight,
      topPadding: kStandardTopPadding,
      bottomPadding: kStandardBottomPadding,
      headerToTextGap: kStandardHeaderToTextGap,
      textToFooterGap: kStandardTextToFooterGap,
      measuredTextHeight: totalTextHeight,
      totalRequiredHeight: totalHeight,
      pairedRows: rows,
      score: score,
    );
  }

  /// Calculates composite aesthetic & readability score S.
  static double _calculateScore({
    required double totalHeight,
    required double fontSize,
    required double measuredHeight,
    required double availableHeight,
    required bool isPaired,
  }) {
    // 1. Aspect score (35%): Perfect 1.0 if fits within 1350px
    double aspectScore;
    if (totalHeight <= kBaseCanvasHeight) {
      aspectScore = 1.0;
    } else {
      aspectScore = math.max(0.0, 1.0 - (totalHeight - kBaseCanvasHeight) / (kMaxSingleAyahHeight - kBaseCanvasHeight));
    }

    // 2. Font score (30%): Normalized preference for larger readable font
    final fontScore = (fontSize - kMinFontSize) / (kMaxFontSize - kMinFontSize);

    // 3. Fill score (20%): Ideal fill ratio is 65% - 85% of available vertical height
    final fillRatio = availableHeight > 0 ? (measuredHeight / availableHeight) : 1.0;
    double fillScore;
    if (fillRatio >= 0.65 && fillRatio <= 0.85) {
      fillScore = 1.0;
    } else if (fillRatio < 0.65) {
      fillScore = math.max(0.0, 1.0 - (0.65 - fillRatio) * 2.0);
    } else {
      fillScore = math.max(0.0, 1.0 - (fillRatio - 0.85) * 4.0);
    }

    // 4. Balance score (15%)
    final balanceScore = isPaired ? 0.95 : 0.90;

    // Extension penalty
    double extensionPenalty = 0.0;
    if (totalHeight > kBaseCanvasHeight) {
      extensionPenalty = 0.25;
    }

    return (0.35 * aspectScore) +
        (0.30 * fontScore) +
        (0.20 * fillScore) +
        (0.15 * balanceScore) -
        extensionPenalty;
  }

  /// Splits multi-Ayah selections across multiple balanced pages.
  static ShareLayoutResult _splitAndCalculatePages({
    required String surahName,
    required List<AyahModel> verses,
  }) {
    // Determine number of pages
    // We estimate based on content height at compact font size (32px)
    final candidateHeightAt32 = measureContinuousTextHeight(
      verses: verses,
      fontSize: 32.0,
      lineHeight: 2.12,
      rosetteSize: _rosetteSizeFor(32.0),
      maxWidth: kStandardContentWidth,
    );

    final availableHeightPerPage = kBaseCanvasHeight - kStandardChromeHeight;
    final estimatedPages = math.max(2, (candidateHeightAt32 / availableHeightPerPage).ceil());

    // Distribute verses evenly across estimatedPages
    final pagesVerses = <List<AyahModel>>[];
    final versesCount = verses.length;
    final baseCount = versesCount ~/ estimatedPages;
    final remainder = versesCount % estimatedPages;

    var startIndex = 0;
    for (int p = 0; p < estimatedPages; p++) {
      final count = baseCount + (p < remainder ? 1 : 0);
      final endIndex = math.min(versesCount, startIndex + count);
      if (startIndex < endIndex) {
        pagesVerses.add(verses.sublist(startIndex, endIndex));
      }
      startIndex = endIndex;
    }

    final totalPages = pagesVerses.length;
    final rawCandidates = <LayoutCandidate>[];

    for (int p = 0; p < totalPages; p++) {
      final batch = pagesVerses[p];
      // Optimize each page independently targeting 1080 × 1350
      final pageCandidate = _findBestCandidate(batch, allowExtension: false) ??
          _evaluateContinuous(
            verses: batch,
            fontSize: kMinFontSize,
            lineHeight: 2.1,
            contentWidth: kCompactContentWidth,
            chromeHeight: kStandardChromeHeight,
            topPadding: kStandardTopPadding,
            bottomPadding: kStandardBottomPadding,
            headerToTextGap: kStandardHeaderToTextGap,
            textToFooterGap: kStandardTextToFooterGap,
            mode: QuranShareLayoutMode.continuous,
          );
      rawCandidates.add(pageCandidate);
    }

    // Harmonize multi-page typography consistency:
    // Avoid jarring font size jumps (e.g. 42px vs 28px) across adjacent pages in the same set.
    if (totalPages > 1) {
      final minFontInSet = rawCandidates.map((c) => c.fontSize).reduce(math.min);
      for (int p = 0; p < totalPages; p++) {
        final currentFont = rawCandidates[p].fontSize;
        if (currentFont - minFontInSet > 4.0) {
          // Harmonize to at most 1 ladder step (4pt) above minFontInSet
          final harmonizedFont = math.min(currentFont, minFontInSet + 4.0);
          final harmonizedCandidate = _evaluateContinuous(
            verses: pagesVerses[p],
            fontSize: harmonizedFont,
            lineHeight: 2.2,
            contentWidth: kStandardContentWidth,
            chromeHeight: kStandardChromeHeight,
            topPadding: kStandardTopPadding,
            bottomPadding: kStandardBottomPadding,
            headerToTextGap: kStandardHeaderToTextGap,
            textToFooterGap: kStandardTextToFooterGap,
            mode: QuranShareLayoutMode.continuous,
          );
          if (harmonizedCandidate.totalRequiredHeight <= kBaseCanvasHeight) {
            rawCandidates[p] = harmonizedCandidate;
          }
        }
      }
    }

    final pagesData = <SharePageData>[];
    for (int p = 0; p < totalPages; p++) {
      pagesData.add(
        _createPageData(
          pageIndex: p + 1,
          totalPages: totalPages,
          verses: pagesVerses[p],
          surahName: surahName,
          candidate: rawCandidates[p],
          canvasHeight: kBaseCanvasHeight,
        ),
      );
    }

    return ShareLayoutResult(pages: pagesData);
  }

  static SharePageData _createPageData({
    required int pageIndex,
    required int totalPages,
    required List<AyahModel> verses,
    required String surahName,
    required LayoutCandidate candidate,
    required double canvasHeight,
  }) {
    return SharePageData(
      pageIndex: pageIndex,
      totalPages: totalPages,
      verses: verses,
      startAyah: verses.isNotEmpty ? verses.first.id : 1,
      endAyah: verses.isNotEmpty ? verses.last.id : 1,
      surahName: surahName,
      canvasWidth: kCanvasWidth,
      canvasHeight: canvasHeight,
      measuredTextHeight: candidate.measuredTextHeight,
      contentWidth: candidate.contentWidth,
      fontSize: candidate.fontSize,
      lineHeight: candidate.lineHeight,
      rosetteSize: candidate.rosetteSize,
      layoutMode: candidate.mode,
      pairedRows: candidate.pairedRows,
      headerToTextGap: candidate.headerToTextGap,
      textToFooterGap: candidate.textToFooterGap,
      topPadding: candidate.topPadding,
      bottomPadding: candidate.bottomPadding,
    );
  }

  /// Proportional rosette size based on font size.
  static double _rosetteSizeFor(double fontSize) {
    return math.max(34.0, math.min(50.0, fontSize * 1.18));
  }

  /// Measures exact text height using TextPainter with identical typography and placeholders.
  static double measureContinuousTextHeight({
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
            fontFamilyFallback: const ['AmiriQuran'],
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
