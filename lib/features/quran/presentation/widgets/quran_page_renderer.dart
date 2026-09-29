import 'package:flutter/material.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/qcf_page_model.dart';
import '../../data/models/quran_display_mode.dart';
import '../../services/qcf_font_service.dart';
import 'ayah_gesture_recognizer.dart';
import 'ayah_rosette.dart';

/// Reading Theme modes matching Medina Mushaf aesthetics.
enum MushafThemeMode {
  ivory, // Royal Ivory (عاجي ملكي - ورق المصحف الكلاسيكي #F6F0E4)
  sepia, // Antique Sepia (بيج تراثي - مريح للعينين نهاراً)
  night, // Quiet Night (ليلي هادئ - أسود داكن بدون وهج)
}

/// Dynamic Ayah Selection Highlight Color options matching authentic digital Mushaf editions.
enum AyahHighlightColor {
  goldenAmber, // #FBF0B9 (Warm Golden Amber - Default Medina classic)
  coralPeach, // #FDE2DC (Soft Coral / Peach Blush)
  emeraldMint, // #E2F4EB (Serene Emerald Mint)
  skyBlue, // #E3EDFB (Quiet Sky Blue)
}

/// Abstract base renderer for authentic Medina Mushaf Pages.
/// Subclassed by [QcfV2PageRenderer] (Normal monochrome Mushaf)
/// and [QcfTajweedV4PageRenderer] (Color-coded Tajweed Mushaf).
abstract class QuranPageRenderer extends StatefulWidget {
  final QcfPageModel pageModel;
  final bool isNightMode;
  final MushafThemeMode themeMode;
  final AyahHighlightColor highlightColor;
  final bool useTransliteratedHeader;
  final int? highlightedAyahId;
  final int? highlightedSurahId;
  final Map<String, dynamic> selectedAyat;
  final Set<String> bookmarks;
  final List<BookmarkModel> richBookmarks;
  final int juz;
  final int hizb;
  final String surahName;
  final FontWeight fontWeight;
  final void Function({required int surahId, required int ayahId}) onAyahTap;
  final void Function({required int surahId, required int ayahId})
      onAyahLongPress;
  final VoidCallback onPageTap;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;

  const QuranPageRenderer({
    super.key,
    required this.pageModel,
    this.isNightMode = false,
    this.themeMode = MushafThemeMode.ivory,
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

  /// Factory constructor to build either [QcfV2PageRenderer] or [QcfTajweedV4PageRenderer]
  /// based on the selected [QuranDisplayMode].
  static Widget create({
    Key? key,
    required QuranDisplayMode displayMode,
    required QcfPageModel pageModel,
    bool isNightMode = false,
    MushafThemeMode themeMode = MushafThemeMode.ivory,
    AyahHighlightColor highlightColor = AyahHighlightColor.goldenAmber,
    bool useTransliteratedHeader = false,
    FontWeight fontWeight = FontWeight.w500,
    int? highlightedAyahId,
    int? highlightedSurahId,
    Map<String, dynamic> selectedAyat = const {},
    Set<String> bookmarks = const {},
    List<BookmarkModel> richBookmarks = const [],
    required int juz,
    required int hizb,
    required String surahName,
    required void Function({required int surahId, required int ayahId})
        onAyahTap,
    required void Function({required int surahId, required int ayahId})
        onAyahLongPress,
    required VoidCallback onPageTap,
    VoidCallback? onNextPage,
    VoidCallback? onPreviousPage,
  }) {
    if (displayMode == QuranDisplayMode.tajweed) {
      return QcfTajweedV4PageRenderer(
        key: key,
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
    return QcfV2PageRenderer(
      key: key,
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

  // Canonical 604-Page Medina Mushaf Canvas Dimensions
  static const double kLogicalCanvasWidth = 385.0;
  static const double kReadingWidth = 353.0; // 385.0 - (16.0 * 2)
  static const double kHeaderHeight = 28.0;
  static const double kFooterHeight = 26.0;

  // 1. Royal Ivory Theme (عاجي ملكي) - Classic Medina Parchment
  static const Color ivoryPaper = Color(0xFFF6F0E4);
  static const Color ivoryText = Color(0xFF231F1D);
  static const Color ivorySecondary = Color(0xFF7A6B5B);
  static const Color ivoryGold = Color(0xFFA67C4A);
  static const Color ivoryFrame = Color(0xFFA67C4A);
  static const Color ivoryFrameSecondary = Color(0xFFD8C5A5);

  // 2. Antique Sepia Theme (بيج تراثي)
  static const Color sepiaPaper = Color(0xFFF3EBD9);
  static const Color sepiaText = Color(0xFF2C2218);
  static const Color sepiaSecondary = Color(0xFF73604C);
  static const Color sepiaGold = Color(0xFFA67C2E);
  static const Color sepiaFrame = Color(0xFFA67C2E);
  static const Color sepiaFrameSecondary = Color(0xFFDACBB0);

  // 3. Quiet Night Theme (ليلي هادئ)
  static const Color nightPaper = Color(0xFF1B201D);
  static const Color nightText = Color(0xFFECE8DF);
  static const Color nightSecondary = Color(0xFFA3988A);
  static const Color nightGold = Color(0xFFD4AF37);
  static const Color nightFrame = Color(0xFF8A7135);
  static const Color nightFrameSecondary = Color(0xFF5E5338);

  // Backward compatibility aliases
  static const Color paperBg = ivoryPaper;
  static const Color textDark = ivoryText;
  static const Color secondaryText = ivorySecondary;
  static const Color goldAccent = ivoryGold;
  static const Color frameGold = ivoryFrame;

  static const Map<int, String> kTransliteratedSurahNames = {
    1: 'Al-Fātihah',
    2: 'Al-Baqarah',
    3: 'Āli ‘Imrān',
    4: 'An-Nisā’',
    5: 'Al-Mā’idah',
    6: 'Al-An‘ām',
    7: 'Al-A‘rāf',
    8: 'Al-Anfāl',
    9: 'At-Tawbah',
    10: 'Yūnus',
    11: 'Hūd',
    12: 'Yūsuf',
    13: 'Ar-Ra‘d',
    14: 'Ibrāhīm',
    15: 'Al-Hijr',
    16: 'An-Nahl',
    17: 'Al-Isrā’',
    18: 'Al-Kahf',
    19: 'Maryam',
    20: 'Tāhā',
    21: 'Al-Anbiyā’',
    22: 'Al-Hajj',
    23: 'Al-Mu’minūn',
    24: 'An-Nūr',
    25: 'Al-Furqān',
    26: 'Ash-Shu‘arā’',
    27: 'An-Naml',
    28: 'Al-Qasas',
    29: 'Al-‘Ankabūt',
    30: 'Ar-Rūm',
    31: 'Luqmān',
    32: 'As-Sajdah',
    33: 'Al-Ahzāb',
    34: 'Saba’',
    35: 'Fātir',
    36: 'Yā-Sīn',
    37: 'As-Sāffāt',
    38: 'Sād',
    39: 'Az-Zumar',
    40: 'Ghāfir',
    41: 'Fussilat',
    42: 'Ash-Shūrā',
    43: 'Az-Zukhruf',
    44: 'Ad-Dukhān',
    45: 'Al-Jāthiyah',
    46: 'Al-Ahqāf',
    47: 'Muhammad',
    48: 'Al-Fath',
    49: 'Al-Hujurāt',
    50: 'Qāf',
    51: 'Adh-Dhāriyāt',
    52: 'At-Tūr',
    53: 'An-Najm',
    54: 'Al-Qamar',
    55: 'Ar-Rahmān',
    56: 'Al-Wāqi‘ah',
    57: 'Al-Hadīd',
    58: 'Al-Mujādilah',
    59: 'Al-Hashr',
    60: 'Al-Mumtahanah',
    61: 'As-Saff',
    62: 'Al-Jumu‘ah',
    63: 'Al-Munāfiqūn',
    64: 'At-Taghābun',
    65: 'At-Talāq',
    66: 'At-Tahrīm',
    67: 'Al-Mulk',
    68: 'Al-Qalam',
    69: 'Al-Hāqqah',
    70: 'Al-Ma‘ārij',
    71: 'Nūh',
    72: 'Al-Jinn',
    73: 'Al-Muzzammil',
    74: 'Al-Muddaththir',
    75: 'Al-Qiyāmah',
    76: 'Al-Insān',
    77: 'Al-Mursalāt',
    78: 'An-Naba’',
    79: 'An-Nāzi‘āt',
    80: '‘Abasa',
    81: 'At-Takwīr',
    82: 'Al-Infitār',
    83: 'Al-Mutaffifīn',
    84: 'Al-Inshiqāq',
    85: 'Al-Burūj',
    86: 'At-Tāriq',
    87: 'Al-A‘lā',
    88: 'Al-Ghāshiyah',
    89: 'Al-Fajr',
    90: 'Al-Balad',
    91: 'Ash-Shams',
    92: 'Al-Layl',
    93: 'Ad-Duhā',
    94: 'Ash-Sharh',
    95: 'At-Tīn',
    96: 'Al-‘Alaq',
    97: 'Al-Qadr',
    98: 'Al-Bayyinah',
    99: 'Az-Zalzalah',
    100: 'Al-‘Ādiyāt',
    101: 'Al-Qāri‘ah',
    102: 'At-Takāthur',
    103: 'Al-‘Asr',
    104: 'Al-Humazah',
    105: 'Al-Fīl',
    106: 'Quraysh',
    107: 'Al-Mā‘ūn',
    108: 'Al-Kawthar',
    109: 'Al-Kāfirūn',
    110: 'An-Nasr',
    111: 'Al-Masad',
    112: 'Al-Ikhlās',
    113: 'Al-Falaq',
    114: 'An-Nās',
  };

  static const Map<int, String> kCanonicalSurahNames = {
    1: 'سُورَةُ ٱلْفَاتِحَةِ',
    2: 'سُورَةُ ٱلْبَقَرَةِ',
    3: 'سُورَةُ آلِ عِمْرَانَ',
    4: 'سُورَةُ النِّسَاءِ',
    5: 'سُورَةُ الْمَائِدَةِ',
    6: 'سُورَةُ الْأَنْعَامِ',
    7: 'سُورَةُ الْأَعْرَافِ',
    8: 'سُورَةُ الْأَنْفَالِ',
    9: 'سُورَةُ التَّوْبَةِ',
    10: 'سُورَةُ يُونُسَ',
    11: 'سُورَةُ هُودٍ',
    12: 'سُورَةُ يُوسُفَ',
    13: 'سُورَةُ الرَّعْدِ',
    14: 'سُورَةُ إِبْرَاهِيمَ',
    15: 'سُورَةُ الْحِجْرِ',
    16: 'سُورَةُ النَّحْلِ',
    17: 'سُورَةُ الْإِسْرَاءِ',
    18: 'سُورَةُ الْكَهْفِ',
    19: 'سُورَةُ مَرْيَمَ',
    20: 'سُورَةُ طٰهٰ',
    21: 'سُورَةُ الْأَنْبِيَاءِ',
    22: 'سُورَةُ الْحَجِّ',
    23: 'سُورَةُ الْمُؤْمِنُونَ',
    24: 'سُورَةُ النُّورِ',
    25: 'سُورَةُ الْفُرْقَانِ',
    26: 'سُورَةُ الشُّعَرَاءِ',
    27: 'سُورَةُ النَّمْلِ',
    28: 'سُورَةُ الْقَصَصِ',
    29: 'سُورَةُ الْعَنْكَبُوتِ',
    30: 'سُورَةُ الرُّومِ',
    31: 'سُورَةُ لُقْمَانَ',
    32: 'سُورَةُ السَّجْدَةِ',
    33: 'سُورَةُ الْأَحْزَابِ',
    34: 'سُورَةُ سَبَإٍ',
    35: 'سُورَةُ فَاطِرٍ',
    36: 'سُورَةُ يسٓ',
    37: 'سُورَةُ الصَّافَّاتِ',
    38: 'سُورَةُ صٓ',
    39: 'سُورَةُ الزُّمَرِ',
    40: 'سُورَةُ غَافِرٍ',
    41: 'سُورَةُ فُصِّلَتْ',
    42: 'سُورَةُ الشُّورَىٰ',
    43: 'سُورَةُ الزُّخْرُفِ',
    44: 'سُورَةُ الدُّخَانِ',
    45: 'سُورَةُ الْجَاثِيَةِ',
    46: 'سُورَةُ الْأَحْقَافِ',
    47: 'سُورَةُ مُحَمَّدٍ',
    48: 'سُورَةُ الْفَتْحِ',
    49: 'سُورَةُ الْحُجُرَاتِ',
    50: 'سُورَةُ قٓ',
    51: 'سُورَةُ الذَّارِيَاتِ',
    52: 'سُورَةُ الطُّورِ',
    53: 'سُورَةُ النَّجْمِ',
    54: 'سُورَةُ الْقَمَرِ',
    55: 'سُورَةُ الرَّحْمٰنِ',
    56: 'سُورَةُ الْوَاقِعَةِ',
    57: 'سُورَةُ الْحَدِيدِ',
    58: 'سُورَةُ الْمُجَادَلَةِ',
    59: 'سُورَةُ الْحَشْرِ',
    60: 'سُورَةُ الْمُمْتَحَنَةِ',
    61: 'سُورَةُ الصَّفِّ',
    62: 'سُورَةُ الْجُمُعَةِ',
    63: 'سُورَةُ الْمُنَافِقُونَ',
    64: 'سُورَةُ التَّغَابُنِ',
    65: 'سُورَةُ الطَّلَاقِ',
    66: 'سُورَةُ التَّحْرِيمِ',
    67: 'سُورَةُ الْمُلْكِ',
    68: 'سُورَةُ الْقَلَمِ',
    69: 'سُورَةُ الْحَاقَّةِ',
    70: 'سُورَةُ الْمَعَارِجِ',
    71: 'سُورَةُ نُوحٍ',
    72: 'سُورَةُ الْجِنِّ',
    73: 'سُورَةُ الْمُزَّمِّلِ',
    74: 'سُورَةُ الْمُدَّثِّرِ',
    75: 'سُورَةُ الْقِيَامَةِ',
    76: 'سُورَةُ الْإِنْسَانِ',
    77: 'سُورَةُ الْمُرْسَلَاتِ',
    78: 'سُورَةُ النَّبَإِ',
    79: 'سُورَةُ النَّازِعَاتِ',
    80: 'سُورَةُ عَبَسَ',
    81: 'سُورَةُ التَّكْوِيرِ',
    82: 'سُورَةُ الْإِنْفِطَارِ',
    83: 'سُورَةُ الْمُطَفِّفِينَ',
    84: 'سُورَةُ الْإِنْشِقَاقِ',
    85: 'سُورَةُ الْبُرُوجِ',
    86: 'سُورَةُ الطَّارِقِ',
    87: 'سُورَةُ الْأَعْلَىٰ',
    88: 'سُورَةُ الْغَاشِيَةِ',
    89: 'سُورَةُ الْفَجْرِ',
    90: 'سُورَةُ الْبَلَدِ',
    91: 'سُورَةُ الشَّمْسِ',
    92: 'سُورَةُ اللَّيْلِ',
    93: 'سُورَةُ الضُّحَىٰ',
    94: 'سُورَةُ الشَّرْحِ',
    95: 'سُورَةُ التِّينِ',
    96: 'سُورَةُ الْعَلَقِ',
    97: 'سُورَةُ الْقَدْرِ',
    98: 'سُورَةُ الْبَيِّنَةِ',
    99: 'سُورَةُ الزَّلْزَلَةِ',
    100: 'سُورَةُ الْعَادِيَاتِ',
    101: 'سُورَةُ الْقَارِعَةِ',
    102: 'سُورَةُ التَّكَاثُرِ',
    103: 'سُورَةُ الْعَصْرِ',
    104: 'سُورَةُ الْهُمَزَةِ',
    105: 'سُورَةُ الْفِيلِ',
    106: 'سُورَةُ قُرَيْشٍ',
    107: 'سُورَةُ الْمَاعُونِ',
    108: 'سُورَةُ الْكَوْثَرِ',
    109: 'سُورَةُ الْكَافِرُونَ',
    110: 'سُورَةُ النَّصْرِ',
    111: 'سُورَةُ الْمَسَدِ',
    112: 'سُورَةُ الْإِخْلَاصِ',
    113: 'سُورَةُ الْفَلَقِ',
    114: 'سُورَةُ النَّاسِ',
  };

  /// The active display mode for this renderer.
  QuranDisplayMode get displayMode;
}

/// A) Normal Mushaf Renderer using QCF V2 pixel-perfect Medina font.
class QcfV2PageRenderer extends QuranPageRenderer {
  const QcfV2PageRenderer({
    super.key,
    required super.pageModel,
    super.isNightMode,
    super.themeMode,
    super.highlightColor,
    super.useTransliteratedHeader,
    super.fontWeight,
    super.highlightedAyahId,
    super.highlightedSurahId,
    super.selectedAyat,
    super.bookmarks,
    super.richBookmarks,
    required super.juz,
    required super.hizb,
    required super.surahName,
    required super.onAyahTap,
    required super.onAyahLongPress,
    required super.onPageTap,
    super.onNextPage,
    super.onPreviousPage,
  });

  @override
  QuranDisplayMode get displayMode => QuranDisplayMode.normal;

  @override
  State<QuranPageRenderer> createState() => _QuranPageRendererState();
}

/// B) Tajweed Colors Mushaf Renderer using QCF Tajweed V4 (Mushaf ID 19)
/// with official COLRv1 color fonts.
class QcfTajweedV4PageRenderer extends QuranPageRenderer {
  const QcfTajweedV4PageRenderer({
    super.key,
    required super.pageModel,
    super.isNightMode,
    super.themeMode,
    super.highlightColor,
    super.useTransliteratedHeader,
    super.fontWeight,
    super.highlightedAyahId,
    super.highlightedSurahId,
    super.selectedAyat,
    super.bookmarks,
    super.richBookmarks,
    required super.juz,
    required super.hizb,
    required super.surahName,
    required super.onAyahTap,
    required super.onAyahLongPress,
    required super.onPageTap,
    super.onNextPage,
    super.onPreviousPage,
  });

  @override
  QuranDisplayMode get displayMode => QuranDisplayMode.tajweed;

  @override
  State<QuranPageRenderer> createState() => _QuranPageRendererState();
}

/// Shared layout and interaction state ensuring 100% parity across normal and tajweed modes.
class _QuranPageRendererState extends State<QuranPageRenderer> {
  bool _fontLoadFailed = false;
  @override
  void initState() {
    super.initState();
    QcfFontService.instance.fontLoadedNotifier.addListener(_onFontLoaded);
    _ensureFont();
  }

  @override
  void didUpdateWidget(QuranPageRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageModel.page != widget.pageModel.page ||
        oldWidget.displayMode != widget.displayMode) {
      _ensureFont();
    }
  }

  @override
  void dispose() {
    QcfFontService.instance.fontLoadedNotifier.removeListener(_onFontLoaded);
    super.dispose();
  }

  void _onFontLoaded() {
    if (QcfFontService.instance.isFontLoaded(
      widget.pageModel.page,
      mode: widget.displayMode,
    )) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _ensureFont() async {
    if (_fontLoadFailed && mounted) setState(() => _fontLoadFailed = false);
    final loaded = await QcfFontService.instance.ensurePageFont(
      widget.pageModel.page,
      mode: widget.displayMode,
    );
    if (mounted && !loaded) setState(() => _fontLoadFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    final pageNum = widget.pageModel.page;
    final isFontLoaded = QcfFontService.instance.isFontLoaded(
      pageNum,
      mode: widget.displayMode,
    );
    final effectiveTheme =
        widget.isNightMode ? MushafThemeMode.night : widget.themeMode;

    final Color bgPaper;
    final Color textDarkColor;
    final Color secondary;
    final Color gold;
    final Color frameColor;
    final Color frameSecondary;

    switch (effectiveTheme) {
      case MushafThemeMode.ivory:
        bgPaper = QuranPageRenderer.ivoryPaper;
        textDarkColor = QuranPageRenderer.ivoryText;
        secondary = QuranPageRenderer.ivorySecondary;
        gold = QuranPageRenderer.ivoryGold;
        frameColor = QuranPageRenderer.ivoryFrame;
        frameSecondary = QuranPageRenderer.ivoryFrameSecondary;
        break;
      case MushafThemeMode.sepia:
        bgPaper = QuranPageRenderer.sepiaPaper;
        textDarkColor = QuranPageRenderer.sepiaText;
        secondary = QuranPageRenderer.sepiaSecondary;
        gold = QuranPageRenderer.sepiaGold;
        frameColor = QuranPageRenderer.sepiaFrame;
        frameSecondary = QuranPageRenderer.sepiaFrameSecondary;
        break;
      case MushafThemeMode.night:
        bgPaper = QuranPageRenderer.nightPaper;
        textDarkColor = QuranPageRenderer.nightText;
        secondary = QuranPageRenderer.nightSecondary;
        gold = QuranPageRenderer.nightGold;
        frameColor = QuranPageRenderer.nightFrame;
        frameSecondary = QuranPageRenderer.nightFrameSecondary;
        break;
    }

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.maxWidth;
          final viewportHeight = constraints.maxHeight;

          final bool isPortrait = viewportHeight > viewportWidth;
          // Safe margin from device bezels widening canvas bounds to fill screen width
          final double hScreenPadding = isPortrait ? 2.0 : 0.0;
          final double effectiveViewportWidth =
              (viewportWidth - (hScreenPadding * 2))
                  .clamp(280.0, viewportWidth);

          final double? targetCanvasHeight = isPortrait
              ? (QuranPageRenderer.kLogicalCanvasWidth *
                      (viewportHeight / effectiveViewportWidth))
                  .clamp(620.0, 1150.0)
              : null;

          const topMargin = 4.0;
          const bottomMargin = 10.0;
          final double? availableLinesHeight =
              targetCanvasHeight != null && targetCanvasHeight >= 640.0
                  ? (targetCanvasHeight -
                      topMargin -
                      QuranPageRenderer.kHeaderHeight -
                      QuranPageRenderer.kFooterHeight -
                      bottomMargin)
                  : null;

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
                  // 1. Medina Mushaf Frame & Content Canvas - Single Page-Level Uniform Scale
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hScreenPadding),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: QuranPageRenderer.kLogicalCanvasWidth,
                          height: targetCanvasHeight,
                          child: CustomPaint(
                            painter: _MushafPageFramePainter(
                              goldColor: frameColor,
                              secondaryGold: frameSecondary,
                              headerHeight: QuranPageRenderer.kHeaderHeight,
                              footerHeight: QuranPageRenderer.kFooterHeight,
                              isOpeningPage: pageNum <= 2,
                            ),
                            child: Column(
                              mainAxisSize: targetCanvasHeight != null
                                  ? MainAxisSize.max
                                  : MainAxisSize.min,
                              mainAxisAlignment: targetCanvasHeight != null
                                  ? MainAxisAlignment.spaceBetween
                                  : MainAxisAlignment.start,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ── Top Margin (starts right under top bar/header) ──
                                    const SizedBox(height: topMargin),

                                    // ── Top Header Bar ──
                                    SizedBox(
                                      height: QuranPageRenderer.kHeaderHeight,
                                      child: _buildHeaderBar(
                                          pageNum, gold, secondary),
                                    ),
                                  ],
                                ),

                                // ── The 15 Quran Lines ──
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: _buildLinesCanvas(
                                    pageNum,
                                    textDarkColor,
                                    secondary,
                                    gold,
                                    QuranPageRenderer.kReadingWidth,
                                    isFontLoaded,
                                    availableLinesHeight: availableLinesHeight,
                                  ),
                                ),

                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ── Bottom Page Num Footer ──
                                    SizedBox(
                                      height: QuranPageRenderer.kFooterHeight,
                                      child: _buildFooterBar(
                                          pageNum, gold, textDarkColor),
                                    ),

                                    // ── Requested: ~10px bottom margin ──
                                    const SizedBox(height: bottomMargin),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  /// Top Header Bar of the Mushaf Page
  Widget _buildHeaderBar(int pageNum, Color gold, Color secondary) {
    if (pageNum <= 2) {
      return Center(
        child: Text(
          pageNum == 1 ? 'سُورَةُ ٱلْفَاتِحَةِ' : 'سُورَةُ ٱلْبَقَرَةِ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            color: gold,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    final int surahId = widget.pageModel.lines
            .expand((l) => l.words)
            .map((w) => w.surahId)
            .whereType<int>()
            .firstOrNull ??
        (widget.pageModel.lines
                .map((l) => int.tryParse(l.surah ?? ''))
                .whereType<int>()
                .firstOrNull ??
            1);

    final String leftText;
    final String rightText;

    if (widget.useTransliteratedHeader) {
      leftText = QuranPageRenderer.kTransliteratedSurahNames[surahId] ??
          widget.surahName;
      rightText = 'Part ${widget.juz}';
    } else {
      final isEven = pageNum % 2 == 0;
      final arabicSurah = widget.surahName.startsWith('سُورَة') ||
              widget.surahName.startsWith('سورة')
          ? widget.surahName
          : 'سُورَةُ ${widget.surahName}';
      final arabicHizb = 'الحِزْبُ ${toArabicDigits(widget.hizb)}';
      leftText = isEven ? arabicSurah : arabicHizb;
      rightText = isEven ? arabicHizb : arabicSurah;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            leftText,
            style: TextStyle(
              fontFamily: widget.useTransliteratedHeader ? 'Cairo' : 'Amiri',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: gold,
            ),
          ),
          Text(
            rightText,
            style: TextStyle(
              fontFamily: widget.useTransliteratedHeader ? 'Cairo' : 'Amiri',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: gold,
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

  /// Renders all 15 lines of the page with authentic proportions and line rhythm.
  Widget _buildLinesCanvas(
    int pageNum,
    Color textDark,
    Color secondary,
    Color gold,
    double readingWidth,
    bool isFontLoaded, {
    double? availableLinesHeight,
  }) {
    final lines = widget.pageModel.lines;
    final fontFamily = isFontLoaded
        ? QcfFontService.fontFamilyForPage(pageNum, mode: widget.displayMode)
        : 'AmiriQuran';

    // In Tajweed mode, if font is not yet loaded, show explicit status (no silent fallback to V2)
    if (widget.displayMode == QuranDisplayMode.tajweed && !isFontLoaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_fontLoadFailed)
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: gold,
                ),
              )
            else
              Icon(Icons.cloud_off_rounded, color: gold, size: 32),
            const SizedBox(height: 14),
            Text(
              _fontLoadFailed
                  ? 'تعذر تحميل خط مصحف التجويد'
                  : 'جاري تحميل خط مصحف التجويد الملوّن…',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'الصفحة ${toArabicDigits(pageNum)}',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                color: secondary.withValues(alpha: 0.8),
              ),
            ),
            if (_fontLoadFailed) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _ensureFont,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: TextButton.styleFrom(foregroundColor: gold),
              ),
            ],
          ],
        ),
      );
    }

    // ── PAGE 1 & 2: Special Layouts (Usually padded/centered vertically) ──
    if (pageNum <= 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              Padding(
                padding:
                    EdgeInsets.symmetric(vertical: pageNum == 1 ? 6.0 : 4.0),
                child: _buildLine(
                  line: line,
                  pageNum: pageNum,
                  textDark: textDark,
                  secondary: secondary,
                  gold: gold,
                  readingWidth: readingWidth,
                  isFontLoaded: isFontLoaded,
                  fontFamily: fontFamily,
                ),
              ),
          ],
        ),
      );
    }

    // ── PAGES 3-604: fixed 15-line Medina grid ──
    // Every page model has exactly 15 lines. Giving each line a fixed slot
    // avoids the uneven vertical gaps produced by intrinsic widget heights.
    if (availableLinesHeight != null && availableLinesHeight >= 540.0) {
      return SizedBox(
        height: availableLinesHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final line in lines)
              Expanded(
                child: Center(
                  child: _buildLine(
                    line: line,
                    pageNum: pageNum,
                    textDark: textDark,
                    secondary: secondary,
                    gold: gold,
                    readingWidth: readingWidth,
                    isFontLoaded: isFontLoaded,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          _buildLine(
            line: line,
            pageNum: pageNum,
            textDark: textDark,
            secondary: secondary,
            gold: gold,
            readingWidth: readingWidth,
            isFontLoaded: isFontLoaded,
            fontFamily: fontFamily,
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
    required bool isFontLoaded,
    required String fontFamily,
  }) {
    if (line.isSurahHeader) {
      return _buildSurahHeaderBanner(line, textDark, gold, readingWidth);
    }
    if (line.isBasmala) {
      return _buildBasmalaLine(
          line, pageNum, textDark, readingWidth, isFontLoaded);
    }
    return _buildTextLine(
      line: line,
      pageNum: pageNum,
      textDark: textDark,
      gold: gold,
      readingWidth: readingWidth,
      isFontLoaded: isFontLoaded,
      fontFamily: fontFamily,
    );
  }

  /// Calligraphic Surah Header Banner (Medina Cartouche)
  Widget _buildSurahHeaderBanner(
    QcfLineModel line,
    Color textColor,
    Color gold,
    double readingWidth,
  ) {
    final effectiveTheme =
        widget.isNightMode ? MushafThemeMode.night : widget.themeMode;
    final bgBanner = effectiveTheme == MushafThemeMode.night
        ? const Color(0xFF1E2420)
        : (effectiveTheme == MushafThemeMode.sepia
            ? const Color(0xFFEFE5CF)
            : const Color(0xFFFAF6EE));
    final borderCol = gold.withValues(
        alpha: effectiveTheme == MushafThemeMode.night ? 0.75 : 0.9);
    final surahNum = int.tryParse(line.surah ?? '');
    final surahTitle = (surahNum != null
            ? QuranPageRenderer.kCanonicalSurahNames[surahNum]
            : null) ??
        line.text ??
        'سُورَةُ ${widget.surahName}';
    const bannerHeight = 34.0;

    return Center(
      child: Container(
        height: bannerHeight,
        width: readingWidth,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: bgBanner,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: gold.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(readingWidth, bannerHeight),
              painter: _MedinaBannerPainter(
                color: borderCol,
                secondaryColor: effectiveTheme == MushafThemeMode.night
                    ? const Color(0xFF5E5338)
                    : const Color(0xFFD8C5A5),
                cartoucheBg: effectiveTheme == MushafThemeMode.night
                    ? const Color(0xFF262E28)
                    : const Color(0xFFFFFDF8),
              ),
            ),
            Text(
              surahTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
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
    bool isFontLoaded,
  ) {
    final useQcf = isFontLoaded && line.qpcV2 != null && line.qpcV2!.isNotEmpty;
    final glyphText =
        useQcf ? line.qpcV2! : 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ';
    final font = useQcf
        ? QcfFontService.fontFamilyForPage(pageNum, mode: widget.displayMode)
        : 'AmiriQuran';

    return Padding(
      padding: EdgeInsets.zero,
      child: Center(
        child: Text(
          glyphText,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: font,
            fontFamilyFallback: const ['AmiriQuran', 'UthmanicHafs'],
            fontSize: 23.0,
            height: 1.25,
            color: textColor,
          ),
        ),
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

  /// Deterministic Text Line preserving intrinsic QCF glyph metrics without artificial line justification
  Widget _buildTextLine({
    required QcfLineModel line,
    required int pageNum,
    required Color textDark,
    required Color gold,
    required double readingWidth,
    required bool isFontLoaded,
    required String fontFamily,
  }) {
    if (line.words.isEmpty) {
      return const SizedBox.shrink();
    }

    final double initialFontSize = (pageNum == 1)
        ? 26.0
        : ((pageNum == 2) ? 25.0 : (isFontLoaded ? 21.0 : 17.5));

    final bool isPage1 = pageNum == 1;
    final bool isLastLineOfPage2 = pageNum == 2 && line.line == 8;
    final bool isShortFinalLine = (line.words.length < 5 && line.line == 15);
    final bool isCentered = isPage1 || isLastLineOfPage2 || isShortFinalLine;

    List<InlineSpan> buildSpans(double fontSize) {
      final spans = <InlineSpan>[];
      for (int i = 0; i < line.words.length; i++) {
        final word = line.words[i];
        spans.add(_buildWordSpan(
          word: word,
          fontFamily: fontFamily,
          wordFontSize: fontSize,
          isLastWord: i == line.words.length - 1,
          goldColor: gold,
          isFontLoaded: isFontLoaded,
        ));
      }
      return spans;
    }

    double wordFontSize = initialFontSize;
    var spans = buildSpans(wordFontSize);

    // Safe inner reading width enforcing protective margins on both right and left edges,
    // guaranteeing Arabic calligraphic glyphs, diacritics, and Ayah rosettes never touch or cross bounds.
    final double safeReadingWidth =
        (readingWidth - 14.0).clamp(280.0, readingWidth);

    double measureWidth(List<InlineSpan> currentSpans, double currentSize) {
      try {
        final placeholderDims = <PlaceholderDimensions>[];
        for (final s in currentSpans) {
          _collectPlaceholderDimensions(s, placeholderDims, currentSize * 0.95);
        }
        final tp = TextPainter(
          text: TextSpan(
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: currentSize,
              fontWeight: widget.fontWeight,
              height: isFontLoaded ? 1.4 : 1.6,
            ),
            children: currentSpans,
          ),
          textDirection: TextDirection.rtl,
        );
        if (placeholderDims.isNotEmpty) {
          tp.setPlaceholderDimensions(placeholderDims);
        }
        tp.layout();
        return tp.width;
      } catch (_) {
        return 0.0;
      }
    }

    double naturalWidth = measureWidth(spans, wordFontSize);

    // 1. If line exceeds safeReadingWidth, scale down font size proportionally so it fits with 100% guarantee,
    // ensuring no characters ever get clipped, touch margins, or bleed outside the page bounds.
    if (naturalWidth > safeReadingWidth && naturalWidth > 0.0) {
      final scale = (safeReadingWidth / naturalWidth).clamp(0.60, 0.99);
      wordFontSize = (initialFontSize * scale);
      spans = buildSpans(wordFontSize);
      naturalWidth = measureWidth(spans, wordFontSize);
    }

    // 2. Dynamic sub-pixel justification:
    // If line is shorter than safeReadingWidth, distribute remaining line space across words,
    // eliminating empty trailing gaps while maintaining safe protective margins from edges.
    double extraWordSpacing = 0.0;
    if (!isCentered && line.words.length > 1 && naturalWidth > 0.0) {
      final spaceCount = line.words.length - 1;
      final diff = safeReadingWidth - naturalWidth;
      if (diff > 0.5 && spaceCount > 0) {
        extraWordSpacing = (diff / spaceCount).clamp(0.0, 5.5);
      }
    }

    return Center(
      child: SizedBox(
        width: safeReadingWidth,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: wordFontSize,
                fontWeight: widget.fontWeight,
                height: isFontLoaded ? 1.4 : 1.6,
                wordSpacing: extraWordSpacing,
              ),
              children: spans,
            ),
            textAlign: isCentered ? TextAlign.center : TextAlign.justify,
            textDirection: TextDirection.rtl,
            softWrap: false,
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
    required bool isFontLoaded,
  }) {
    final surahId = word.surahId ?? 1;
    final ayahId = word.ayahId ?? 1;
    final ayahKey = '$surahId:$ayahId';

    final isSelected = widget.selectedAyat.containsKey(ayahKey);
    final isHighlighted = widget.highlightedAyahId == ayahId &&
        (widget.highlightedSurahId == null ||
            widget.highlightedSurahId == surahId);
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

    final effectiveTheme =
        widget.isNightMode ? MushafThemeMode.night : widget.themeMode;
    final Color themeDefaultText;
    switch (effectiveTheme) {
      case MushafThemeMode.ivory:
        themeDefaultText = QuranPageRenderer.ivoryText;
        break;
      case MushafThemeMode.sepia:
        themeDefaultText = QuranPageRenderer.sepiaText;
        break;
      case MushafThemeMode.night:
        themeDefaultText = QuranPageRenderer.nightText;
        break;
    }

    Color wordTextColor;
    if (effectiveTheme == MushafThemeMode.night) {
      if (isSelected || isHighlighted) {
        wordTextColor = const Color(0xFFFDE68A);
      } else if (anyHighlighted) {
        wordTextColor = themeDefaultText.withValues(alpha: 0.55);
      } else {
        wordTextColor = themeDefaultText;
      }
    } else {
      // In light/ivory/sepia mode, keep text crisp dark charcoal for 100% legibility on pastel highlight
      if (anyHighlighted && !isHighlighted && !isSelected) {
        wordTextColor = themeDefaultText.withValues(alpha: 0.65);
      } else {
        wordTextColor = themeDefaultText;
      }
    }

    Color? wordBgColor;
    if (isSelected || isHighlighted) {
      switch (widget.highlightColor) {
        case AyahHighlightColor.goldenAmber:
          wordBgColor = effectiveTheme == MushafThemeMode.night
              ? const Color(0xFF38321E)
              : const Color(0xFFFBF0B9);
          break;
        case AyahHighlightColor.coralPeach:
          wordBgColor = effectiveTheme == MushafThemeMode.night
              ? const Color(0xFF3E2624)
              : const Color(0xFFFDE2DC);
          break;
        case AyahHighlightColor.emeraldMint:
          wordBgColor = effectiveTheme == MushafThemeMode.night
              ? const Color(0xFF1E3528)
              : const Color(0xFFE2F4EB);
          break;
        case AyahHighlightColor.skyBlue:
          wordBgColor = effectiveTheme == MushafThemeMode.night
              ? const Color(0xFF1E2B38)
              : const Color(0xFFE3EDFB);
          break;
      }
    } else if (isBookmarked) {
      wordBgColor = bookmarkColor.withValues(alpha: 0.12);
    }

    final suffix = isLastWord ? '' : ' ';

    // ── QCF Mode: High-Fidelity Native King Fahd Ligatures & Ayah Rosettes ──
    if (isFontLoaded && word.qpcV2.isNotEmpty) {
      return TextSpan(
        text: '${word.qpcV2}$suffix',
        recognizer: AyahGestureRecognizer()
          ..onTap = () {
            widget.onAyahTap(surahId: surahId, ayahId: ayahId);
          }
          ..onLongPress = () {
            widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
          },
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: wordFontSize,
          fontWeight: widget.fontWeight,
          color: wordTextColor,
          backgroundColor: wordBgColor,
          height: 1.4,
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
                ..onTap = () {
                  widget.onAyahTap(surahId: surahId, ayahId: ayahId);
                }
                ..onLongPress = () {
                  widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
                },
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: wordFontSize,
                fontWeight: widget.fontWeight,
                color: wordTextColor,
                backgroundColor: wordBgColor,
                height: 1.65,
              ),
            ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            style: TextStyle(
              backgroundColor: wordBgColor,
            ),
            child: GestureDetector(
              onTap: () {
                widget.onAyahTap(surahId: surahId, ayahId: ayahId);
              },
              onLongPress: () {
                widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
              },
              child: Container(
                color: wordBgColor,
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: SizedBox(
                  width: (wordFontSize * 0.95).clamp(19.0, 24.0),
                  height: (wordFontSize * 0.95).clamp(19.0, 24.0),
                  child: AyahRosette(
                    ayahNumber: ayahId,
                    borderColor: goldColor,
                    fillColor: wordBgColor,
                    textColor: effectiveTheme == MushafThemeMode.night
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFF382A1B),
                    highlightBgColor: wordBgColor,
                    size: (wordFontSize * 0.95).clamp(19.0, 24.0),
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
        ..onTap = () {
          widget.onAyahTap(surahId: surahId, ayahId: ayahId);
        }
        ..onLongPress = () {
          widget.onAyahLongPress(surahId: surahId, ayahId: ayahId);
        },
      style: TextStyle(
        fontFamily: 'AmiriQuran',
        fontSize: wordFontSize,
        fontWeight: widget.fontWeight,
        color: wordTextColor,
        backgroundColor: wordBgColor,
        height: 1.65,
      ),
    );
  }
}

/// Ornate Medina Mushaf Page Frame Painter with classical double border and corner arabesques.
class _MushafPageFramePainter extends CustomPainter {
  final Color goldColor;
  final Color secondaryGold;
  final double headerHeight;
  final double footerHeight;
  final bool isOpeningPage;

  const _MushafPageFramePainter({
    required this.goldColor,
    required this.secondaryGold,
    required this.headerHeight,
    required this.footerHeight,
    this.isOpeningPage = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isOpeningPage) {
      _paintOpeningIlluminatedFrame(canvas, size);
      return;
    }

    _paintStandardMedinaFrame(canvas, size);
  }

  void _paintStandardMedinaFrame(Canvas canvas, Size size) {
    // Pure clean, borderless Medina layout matching modern digital Mushaf aesthetics
  }

  void _paintOpeningIlluminatedFrame(Canvas canvas, Size size) {
    const innerGap = 5.0;
    final crownPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _drawArchedCrown(canvas, Offset(size.width / 2, innerGap + 2), crownPaint,
        isTop: true);
    _drawArchedCrown(
        canvas, Offset(size.width / 2, size.height - innerGap - 2), crownPaint,
        isTop: false);
  }

  void _drawArchedCrown(Canvas canvas, Offset center, Paint paint,
      {required bool isTop}) {
    final sy = isTop ? 1.0 : -1.0;
    final path = Path();
    path.moveTo(center.dx - 28, center.dy);
    path.quadraticBezierTo(
        center.dx - 14, center.dy + (8 * sy), center.dx, center.dy + (12 * sy));
    path.quadraticBezierTo(
        center.dx + 14, center.dy + (8 * sy), center.dx + 28, center.dy);
    canvas.drawPath(path, paint);

    final pearlPaint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(center.dx, center.dy + (14 * sy)), 1.8, pearlPaint);
  }

  @override
  bool shouldRepaint(_MushafPageFramePainter oldDelegate) =>
      oldDelegate.goldColor != goldColor ||
      oldDelegate.secondaryGold != secondaryGold ||
      oldDelegate.isOpeningPage != isOpeningPage;
}

/// Ornaments Painter for Surah Header Banners (Authentic Medina Cartouche)
class _MedinaBannerPainter extends CustomPainter {
  final Color color;
  final Color secondaryColor;
  final Color cartoucheBg;

  const _MedinaBannerPainter({
    required this.color,
    required this.secondaryColor,
    required this.cartoucheBg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final hairlinePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    final fillGold = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cartoucheFill = Paint()
      ..color = cartoucheBg
      ..style = PaintingStyle.fill;

    // 1. Outer Frame with rounded corners
    final outerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(outerRRect, borderPaint);

    // 2. Inner hairline frame inset by 2.5px
    final innerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2.5, 2.5, size.width - 5.0, size.height - 5.0),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(innerRRect, hairlinePaint);

    // 3. Ornate Corner Arabesque Loops (connecting inner and outer corners)
    for (final corner in [
      const Offset(2.5, 2.5),
      Offset(size.width - 2.5, 2.5),
      Offset(2.5, size.height - 2.5),
      Offset(size.width - 2.5, size.height - 2.5),
    ]) {
      canvas.drawCircle(corner, 1.2, fillGold);
    }

    final centerY = size.height / 2;
    const cartoucheW = 160.0;
    const cartoucheH = 34.0;
    final cartoucheLeft = (size.width - cartoucheW) / 2;
    final cartoucheRight = cartoucheLeft + cartoucheW;
    final cartoucheTop = (size.height - cartoucheH) / 2;
    final cartoucheBottom = cartoucheTop + cartoucheH;

    // 4. Center Medina Cartouche Path (bracketed scalloped arcs)
    final cartouchePath = Path();
    cartouchePath.moveTo(cartoucheLeft + 12.0, cartoucheTop);
    cartouchePath.lineTo(cartoucheRight - 12.0, cartoucheTop);

    // Right scalloped bracket
    cartouchePath.quadraticBezierTo(
      cartoucheRight,
      cartoucheTop,
      cartoucheRight,
      cartoucheTop + 8.0,
    );
    cartouchePath.arcToPoint(
      Offset(cartoucheRight + 6.0, centerY),
      radius: const Radius.circular(8.0),
      clockwise: true,
    );
    cartouchePath.arcToPoint(
      Offset(cartoucheRight, cartoucheBottom - 8.0),
      radius: const Radius.circular(8.0),
      clockwise: true,
    );
    cartouchePath.quadraticBezierTo(
      cartoucheRight,
      cartoucheBottom,
      cartoucheRight - 12.0,
      cartoucheBottom,
    );

    // Bottom edge
    cartouchePath.lineTo(cartoucheLeft + 12.0, cartoucheBottom);

    // Left scalloped bracket
    cartouchePath.quadraticBezierTo(
      cartoucheLeft,
      cartoucheBottom,
      cartoucheLeft,
      cartoucheBottom - 8.0,
    );
    cartouchePath.arcToPoint(
      Offset(cartoucheLeft - 6.0, centerY),
      radius: const Radius.circular(8.0),
      clockwise: true,
    );
    cartouchePath.arcToPoint(
      Offset(cartoucheLeft, cartoucheTop + 8.0),
      radius: const Radius.circular(8.0),
      clockwise: true,
    );
    cartouchePath.quadraticBezierTo(
      cartoucheLeft,
      cartoucheTop,
      cartoucheLeft + 12.0,
      cartoucheTop,
    );
    cartouchePath.close();

    // Draw cartouche subtle background & stroke
    canvas.drawPath(cartouchePath, cartoucheFill);
    canvas.drawPath(cartouchePath, borderPaint);

    // Inner hairline outline of the cartouche
    canvas.drawPath(cartouchePath, hairlinePaint);

    // Small finial pearls on the cartouche tips
    canvas.drawCircle(Offset(cartoucheLeft - 8.5, centerY), 1.8, fillGold);
    canvas.drawCircle(Offset(cartoucheRight + 8.5, centerY), 1.8, fillGold);

    // 5. Left & Right Wing Arabesque Scrollwork
    _drawWingArabesque(canvas, size,
        isLeft: true, cartoucheEdge: cartoucheLeft - 10.0, centerY: centerY);
    _drawWingArabesque(canvas, size,
        isLeft: false, cartoucheEdge: cartoucheRight + 10.0, centerY: centerY);
  }

  void _drawWingArabesque(
    Canvas canvas,
    Size size, {
    required bool isLeft,
    required double cartoucheEdge,
    required double centerY,
  }) {
    final goldPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final hairlinePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.65;

    final fillGold = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final margin = isLeft ? 12.0 : size.width - 12.0;
    final midX = (cartoucheEdge + margin) / 2;

    // Central Rosette Medallion in the wing
    canvas.drawCircle(Offset(midX, centerY), 6.5, goldPaint);
    canvas.drawCircle(Offset(midX, centerY), 4.2, hairlinePaint);
    canvas.drawCircle(Offset(midX, centerY), 1.6, fillGold);

    // Horizontal spine
    canvas.drawLine(
        Offset(margin, centerY), Offset(midX - 7.5, centerY), hairlinePaint);
    canvas.drawLine(Offset(midX + 7.5, centerY), Offset(cartoucheEdge, centerY),
        hairlinePaint);

    // Flowing Symmetrical Volutes (Spirals / Palmettes)
    final path = Path();
    final dir = isLeft ? 1.0 : -1.0;

    // Top spiral curve
    path.moveTo(midX, centerY - 6.5);
    path.cubicTo(
      midX - (12.0 * dir),
      centerY - 14.0,
      midX - (22.0 * dir),
      centerY - 8.0,
      midX - (16.0 * dir),
      centerY - 3.0,
    );

    // Bottom spiral curve
    path.moveTo(midX, centerY + 6.5);
    path.cubicTo(
      midX - (12.0 * dir),
      centerY + 14.0,
      midX - (22.0 * dir),
      centerY + 8.0,
      midX - (16.0 * dir),
      centerY + 3.0,
    );

    // Outer arching palmette tendrils extending toward frame
    path.moveTo(midX + (7.0 * dir), centerY - 4.0);
    path.quadraticBezierTo(
      midX + (18.0 * dir),
      centerY - 11.0,
      cartoucheEdge - (4.0 * dir),
      centerY - 5.0,
    );

    path.moveTo(midX + (7.0 * dir), centerY + 4.0);
    path.quadraticBezierTo(
      midX + (18.0 * dir),
      centerY + 11.0,
      cartoucheEdge - (4.0 * dir),
      centerY + 5.0,
    );

    canvas.drawPath(path, hairlinePaint);

    // Decorative pearls on tendril tips
    canvas.drawCircle(
        Offset(midX - (16.0 * dir), centerY - 3.0), 1.2, fillGold);
    canvas.drawCircle(
        Offset(midX - (16.0 * dir), centerY + 3.0), 1.2, fillGold);
  }

  @override
  bool shouldRepaint(_MedinaBannerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.cartoucheBg != cartoucheBg;
}
