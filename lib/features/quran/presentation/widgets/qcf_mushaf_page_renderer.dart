import 'package:flutter/material.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/qcf_page_model.dart';
import '../../data/models/quran_display_mode.dart';
import 'quran_page_renderer.dart';

export 'quran_page_renderer.dart' show MushafThemeMode, AyahHighlightColor, QuranPageRenderer, QcfV2PageRenderer, QcfTajweedV4PageRenderer;

/// Backward-compatible wrapper delegating to the unified [QuranPageRenderer] architecture.
class QcfMushafPageRenderer extends StatelessWidget {
  final QcfPageModel pageModel;
  final bool isNightMode;
  final MushafThemeMode themeMode;
  final QuranDisplayMode displayMode;
  final AyahHighlightColor highlightColor;
  final bool useTransliteratedHeader;
  final FontWeight fontWeight;
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
    this.displayMode = QuranDisplayMode.normal,
    this.highlightColor = AyahHighlightColor.goldenAmber,
    this.useTransliteratedHeader = false,
    this.fontWeight = FontWeight.w500,
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

  // Color aliases for backward compatibility
  static const Color ivoryPaper = QuranPageRenderer.ivoryPaper;
  static const Color ivoryText = QuranPageRenderer.ivoryText;
  static const Color ivorySecondary = QuranPageRenderer.ivorySecondary;
  static const Color ivoryGold = QuranPageRenderer.ivoryGold;
  static const Color ivoryFrame = QuranPageRenderer.ivoryFrame;

  static const Color sepiaPaper = QuranPageRenderer.sepiaPaper;
  static const Color sepiaText = QuranPageRenderer.sepiaText;
  static const Color sepiaSecondary = QuranPageRenderer.sepiaSecondary;
  static const Color sepiaGold = QuranPageRenderer.sepiaGold;
  static const Color sepiaFrame = QuranPageRenderer.sepiaFrame;

  static const Color nightPaper = QuranPageRenderer.nightPaper;
  static const Color nightText = QuranPageRenderer.nightText;
  static const Color nightSecondary = QuranPageRenderer.nightSecondary;
  static const Color nightGold = QuranPageRenderer.nightGold;
  static const Color nightFrame = QuranPageRenderer.nightFrame;

  static const Color paperBg = ivoryPaper;
  static const Color textDark = ivoryText;
  static const Color secondaryText = ivorySecondary;
  static const Color goldAccent = ivoryGold;
  static const Color frameGold = ivoryFrame;

  @override
  Widget build(BuildContext context) {
    return QuranPageRenderer.create(
      displayMode: displayMode,
      pageModel: pageModel,
      isNightMode: isNightMode,
      themeMode: themeMode,
      highlightColor: highlightColor,
      useTransliteratedHeader: useTransliteratedHeader,
      fontWeight: fontWeight,
      highlightedAyahId: highlightedAyahId,
      highlightedSurahId: highlightedSurahId,
      selectedAyat: selectedAyat,
      bookmarks: bookmarks,
      richBookmarks: richBookmarks,
      juz: juz,
      hizb: hizb,
      surahName: surahName,
      onAyahTap: onAyahTap,
      onAyahLongPress: onAyahLongPress,
      onPageTap: onPageTap,
      onNextPage: onNextPage,
      onPreviousPage: onPreviousPage,
    );
  }
}
