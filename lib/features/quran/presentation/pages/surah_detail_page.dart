import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/ayah_model.dart';
import '../../data/models/last_read_model.dart';
import '../../data/models/mushaf_page_model.dart';
import '../../data/models/surah_model.dart';
import '../../data/repositories/quran_repository.dart';
import '../bloc/quran_bloc.dart';
import '../bloc/quran_event.dart';
import '../bloc/quran_state.dart';
import '../widgets/ayah_rosette.dart';
import '../widgets/mushaf_info_sheets.dart';
import '../../data/models/bookmark_model.dart';
import '../widgets/bookmark_collection_dialog.dart';
import '../widgets/quran_share_composer_dialog.dart';
import '../../data/models/qcf_page_model.dart';
import '../../services/mushaf_image_service.dart';
import '../../services/qcf_layout_service.dart';
import '../widgets/qcf_mushaf_page_renderer.dart';

class SurahDetailPage extends StatefulWidget {
  final SurahModel surah;
  final int initialAyah;

  const SurahDetailPage({
    super.key,
    required this.surah,
    this.initialAyah = 1,
  });

  // Deterministic Medina Mushaf Reference Dimensions & Aspect Ratio
  // King Fahd Medina Mushaf Page Geometry (Rigid 385 x 620 logical canvas)
  static const double kMushafPageWidth = 385.0;
  static const double kMushafPageHeight = 620.0;
  static const double kMushafAspectRatio = kMushafPageWidth / kMushafPageHeight;

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  late final PageController _pageController;
  late int _currentPage;
  int? _highlightedAyahId;
  int? _highlightedSurahId;
  MushafThemeMode _themeMode = MushafThemeMode.ivory;
  bool _isNightMode = false;
  double _fontSize = 24.0;
  double _fontWeightValue = 0.0;

  bool _showControls = true;

  @visibleForTesting
  void toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  // Multi-Ayah Selection State
  bool _isSelectionMode = false;
  final Map<String, ({int surahId, String surahName, AyahModel ayah, int page})> _selectedAyat = {};

  void _toggleAyahSelection({
    required int surahId,
    required String surahName,
    required AyahModel ayah,
    required int page,
  }) {
    final key = '$surahId:${ayah.id}';
    setState(() {
      if (_selectedAyat.containsKey(key)) {
        _selectedAyat.remove(key);
        if (_selectedAyat.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _isSelectionMode = true;
        // If there are already selected ayahs in the same surah, fill the continuous range
        final sameSurahAyat = _selectedAyat.values.where((e) => e.surahId == surahId).toList();
        if (sameSurahAyat.isNotEmpty) {
          final repo = context.read<QuranRepository>();
          final surah = repo.getSurahById(surahId);
          if (surah != null && surah.verses.isNotEmpty) {
            final minAyahId = sameSurahAyat.map((e) => e.ayah.id).reduce((a, b) => a < b ? a : b);
            final maxAyahId = sameSurahAyat.map((e) => e.ayah.id).reduce((a, b) => a > b ? a : b);

            final rangeStart = ayah.id < minAyahId ? ayah.id : minAyahId;
            final rangeEnd = ayah.id > maxAyahId ? ayah.id : maxAyahId;

            for (final v in surah.verses) {
              if (v.id >= rangeStart && v.id <= rangeEnd) {
                _selectedAyat['$surahId:${v.id}'] = (
                  surahId: surahId,
                  surahName: surahName,
                  ayah: v,
                  page: v.page,
                );
              }
            }
            return;
          }
        }

        _selectedAyat[key] = (
          surahId: surahId,
          surahName: surahName,
          ayah: ayah,
          page: page,
        );
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAyat.clear();
      _isSelectionMode = false;
    });
  }

  void _bookmarkSelectedAyat() {
    if (_selectedAyat.isEmpty) return;
    final list = _selectedAyat.values
        .map((e) => (surahId: e.surahId, ayahId: e.ayah.id, page: e.page))
        .toList();
    BookmarkCollectionDialog.show(
      context,
      ayat: list,
      surahName: _selectedAyat.values.first.surahName,
    );
    _clearSelection();
  }

  void _shareSelectedAyat() {
    if (_selectedAyat.isEmpty) return;
    final sorted = _selectedAyat.values.toList()
      ..sort((a, b) => a.ayah.id.compareTo(b.ayah.id));
    final first = sorted.first;
    final last = sorted.last;
    QuranShareComposerDialog.show(
      context,
      surahId: first.surahId,
      surahName: first.surahName,
      initialStartAyah: first.ayah.id,
      initialEndAyah: last.ayah.id,
    );
    _clearSelection();
  }

  void _copySelectedAyat() {
    if (_selectedAyat.isEmpty) return;
    final sorted = _selectedAyat.values.toList()
      ..sort((a, b) {
        if (a.surahId != b.surahId) return a.surahId.compareTo(b.surahId);
        return a.ayah.id.compareTo(b.ayah.id);
      });

    final buffer = StringBuffer();
    buffer.write('﴿ ');
    for (int i = 0; i < sorted.length; i++) {
      final item = sorted[i];
      buffer.write(item.ayah.text);
      buffer.write(' ﴿${toArabicDigits(item.ayah.id)}﴾');
      if (i < sorted.length - 1) buffer.write(' ');
    }
    buffer.writeln(' ﴾');
    buffer.writeln();

    final first = sorted.first;
    final last = sorted.last;
    if (first.surahId == last.surahId) {
      if (first.ayah.id == last.ayah.id) {
        buffer.write('سورة ${first.surahName} • الآية ${toArabicDigits(first.ayah.id)}');
      } else {
        buffer.write('سورة ${first.surahName} • الآيات ${toArabicDigits(first.ayah.id)}–${toArabicDigits(last.ayah.id)}');
      }
    } else {
      buffer.write('سورة ${first.surahName} [${toArabicDigits(first.ayah.id)}] — سورة ${last.surahName} [${toArabicDigits(last.ayah.id)}]');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppSnackBar.showSuccess(context, 'تم نسخ الآيات الكريمة بنص متواصل بنجاح');
    _clearSelection();
  }

  // 1. Royal Ivory Theme (عاجي ملكي) - Classic Medina Mushaf
  static const Color paperBg = Color(0xFFFAF6EE);
  static const Color paperBorder = Color(0xFFD8C7A8);
  static const Color textDark = Color(0xFF231F1B);
  static const Color bronzeAccent = Color(0xFF7A6B5B);
  static const Color goldAccent = Color(0xFFB38938);

  // 2. Antique Sepia Theme (بيج تراثي)
  static const Color sepiaPaper = Color(0xFFF3EBD9);
  static const Color sepiaBorder = Color(0xFFDACBB0);
  static const Color sepiaText = Color(0xFF2C2218);
  static const Color sepiaBronze = Color(0xFF73604C);

  // 3. Quiet Night Theme (ليلي هادئ)
  static const Color nightPaper = Color(0xFF121714);
  static const Color nightBorder = Color(0xFF38433D);
  static const Color nightText = Color(0xFFECE8DF);
  static const Color nightBronze = Color(0xFFD4AF37);

  Color get _currentBgColor {
    switch (_themeMode) {
      case MushafThemeMode.ivory:
        return paperBg;
      case MushafThemeMode.sepia:
        return sepiaPaper;
      case MushafThemeMode.night:
        return nightPaper;
    }
  }

  Color get _currentTextColor {
    switch (_themeMode) {
      case MushafThemeMode.ivory:
        return textDark;
      case MushafThemeMode.sepia:
        return sepiaText;
      case MushafThemeMode.night:
        return nightText;
    }
  }

  Color get _currentBorderColor {
    switch (_themeMode) {
      case MushafThemeMode.ivory:
        return paperBorder;
      case MushafThemeMode.sepia:
        return sepiaBorder;
      case MushafThemeMode.night:
        return nightBorder;
    }
  }

  Color get _currentAccentColor {
    switch (_themeMode) {
      case MushafThemeMode.ivory:
        return bronzeAccent;
      case MushafThemeMode.sepia:
        return sepiaBronze;
      case MushafThemeMode.night:
        return nightBronze;
    }
  }

  static const double kMushafPageWidth = SurahDetailPage.kMushafPageWidth;
  static const double kMushafPageHeight = SurahDetailPage.kMushafPageHeight;
  static const double kMushafAspectRatio = SurahDetailPage.kMushafAspectRatio;

  @override
  void initState() {
    super.initState();
    final repo = context.read<QuranRepository>();
    final targetPage = repo.getPageForAyah(widget.surah.id, widget.initialAyah);
    _currentPage = targetPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
    _highlightedAyahId = widget.initialAyah >= 1 ? widget.initialAyah : null;
    _highlightedSurahId = widget.initialAyah >= 1 ? widget.surah.id : null;
    QcfLayoutService.instance.loadPage(_currentPage);

    final savedTheme = repo.getMushafTheme();
    if (savedTheme == 'sepia') {
      _themeMode = MushafThemeMode.sepia;
    } else if (savedTheme == 'night') {
      _themeMode = MushafThemeMode.night;
    } else {
      _themeMode = MushafThemeMode.ivory;
    }
    _isNightMode = _themeMode == MushafThemeMode.night;

    final qState = context.read<QuranBloc>().state;
    if (qState is QuranLoaded) {
      _fontSize = qState.fontSize;
      _fontWeightValue = qState.fontWeightValue;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordCurrentPageAsLastRead();
    });
  }

  void _setMushafTheme(MushafThemeMode mode) {
    setState(() {
      _themeMode = mode;
      _isNightMode = mode == MushafThemeMode.night;
    });
    final themeStr = mode == MushafThemeMode.sepia
        ? 'sepia'
        : (mode == MushafThemeMode.night ? 'night' : 'ivory');
    context.read<QuranRepository>().setMushafTheme(themeStr);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  FontWeight _computeFontWeight() {
    // Map 0.0-1.0 to FontWeight.w400 - FontWeight.w900
    if (_fontWeightValue <= 0.0) return FontWeight.w400;
    if (_fontWeightValue <= 0.25) return FontWeight.w500;
    if (_fontWeightValue <= 0.50) return FontWeight.w600;
    if (_fontWeightValue <= 0.75) return FontWeight.w700;
    return FontWeight.w900;
  }

  void _recordCurrentPageAsLastRead() {
    final repo = context.read<QuranRepository>();
    final pageData = repo.getPage(_currentPage);
    if (pageData == null || pageData.segments.isEmpty) return;

    final firstSeg = pageData.segments.first;
    final firstAyah = firstSeg.verses.isNotEmpty ? firstSeg.verses.first : null;

    context.read<QuranBloc>().add(
          UpdateLastReadEvent(
            LastReadModel(
              surahId: firstSeg.surahId,
              surahName: firstSeg.surahName,
              ayahId: firstAyah?.id ?? 1,
              page: _currentPage,
              timestamp: DateTime.now(),
            ),
          ),
        );
  }

  void _onAyahTap({
    required int surahId,
    required String surahName,
    required AyahModel ayah,
    required int page,
  }) {
    if (_isSelectionMode) {
      _toggleAyahSelection(
        surahId: surahId,
        surahName: surahName,
        ayah: ayah,
        page: page,
      );
    } else {
      // Single tap does NOT show action menu (Tafseer/Bookmarks).
      // Only clears active highlight if any exists.
      if (_highlightedAyahId != null) {
        setState(() {
          _highlightedAyahId = null;
          _highlightedSurahId = null;
        });
      }
    }
  }

  void _onAyahLongPress({
    required int surahId,
    required String surahName,
    required AyahModel ayah,
  }) {
    HapticFeedback.mediumImpact();
    _showAyahActions(surahId, surahName, ayah);
  }

  @visibleForTesting
  void showAyahActions(int surahId, String surahName, AyahModel ayah) {
    _showAyahActions(surahId, surahName, ayah);
  }

  void _showAyahActions(int surahId, String surahName, AyahModel ayah) {
    setState(() {
      _highlightedAyahId = ayah.id;
      _highlightedSurahId = surahId;
    });

    final isBookmarked = context.read<QuranBloc>().state is QuranLoaded &&
        (context.read<QuranBloc>().state as QuranLoaded)
            .bookmarks
            .contains('$surahId:${ayah.id}');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: _isNightMode ? nightPaper : paperBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(
                color: (_isNightMode ? nightBronze : goldAccent).withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isNightMode ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _isNightMode ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Top: Surah name + Ayah number
                Text(
                  'سورة $surahName • الآية ${toArabicDigits(ayah.id)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _isNightMode ? nightBronze : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),

                // Top: Selected Ayah text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isNightMode ? Colors.black26 : Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_isNightMode ? Colors.white12 : paperBorder).withValues(alpha: 0.8),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    ayah.text,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'UthmanicHafs',
                      fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.8,
                      color: _isNightMode ? nightText : textDark,
                    ),
                  ),
                ),

                if (ayah.sajda || ayah.text.contains('\u06e9')) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_isNightMode ? nightBronze : goldAccent).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (_isNightMode ? nightBronze : goldAccent).withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mosque_rounded,
                          size: 16,
                          color: _isNightMode ? nightBronze : bronzeAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'سجدة تلاوة مستحبة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _isNightMode ? nightText : textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Row 1: [ تفسير ]   [ حفظ كعلامة ]
                Row(
                  children: [
                    _buildAyahSheetActionButton(
                      icon: Icons.menu_book_rounded,
                      label: 'تفسير',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showTafsirSheet(context, surahId, surahName, ayah);
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildAyahSheetActionButton(
                      icon: isBookmarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                      label: isBookmarked ? 'محفوظة كعلامة' : 'حفظ كعلامة',
                      isHighlighted: isBookmarked,
                      onTap: () {
                        Navigator.pop(ctx);
                        BookmarkCollectionDialog.show(
                          context,
                          ayat: [(surahId: surahId, ayahId: ayah.id, page: ayah.page)],
                          surahName: surahName,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Row 2: [ نسخ الآية ] [ مشاركة ]
                Row(
                  children: [
                    _buildAyahSheetActionButton(
                      icon: Icons.copy_rounded,
                      label: 'نسخ الآية',
                      onTap: () {
                        Navigator.pop(ctx);
                        Clipboard.setData(ClipboardData(
                          text: '﴿ ${ayah.text} ﴾\nسورة $surahName — الآية ${toArabicDigits(ayah.id)}',
                        ));
                        AppSnackBar.showSuccess(context, 'تم نسخ الآية الكريمة');
                      },
                    ),
                    const SizedBox(width: 10),
                    _buildAyahSheetActionButton(
                      icon: Icons.share_rounded,
                      label: 'مشاركة',
                      onTap: () {
                        Navigator.pop(ctx);
                        QuranShareComposerDialog.show(
                          context,
                          surahId: surahId,
                          surahName: surahName,
                          initialStartAyah: ayah.id,
                          initialEndAyah: ayah.id,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bottom Secondary Action: [ تحديد آيات متعددة للمشاركة أو الحفظ ]
                Material(
                  color: _isNightMode
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleAyahSelection(
                        surahId: surahId,
                        surahName: surahName,
                        ayah: ayah,
                        page: ayah.page,
                      );
                    },
                    child: Container(
                      height: 44,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isNightMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : paperBorder.withValues(alpha: 0.8),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 18,
                            color: _isNightMode ? AppColors.accentGoldLight : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تحديد آيات متعددة للمشاركة أو الحفظ',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _isNightMode ? nightText : textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _highlightedAyahId = null;
          _highlightedSurahId = null;
        });
      }
    });
  }

  void _showTafsirSheet(BuildContext context, int surahId, String surahName, AyahModel ayah) {
    final tafsirText =
        'قوله تعالى في سورة $surahName، الآية ${toArabicDigits(ayah.id)}:\n'
        '﴿ ${ayah.text} ﴾\n\n'
        'هذه الآية الكريمة من كتاب الله المحكم، تبيّن معالم الهداية ودلائل الإيمان، وتدعو المؤمن للتدبر في كلام رب العالمين واستشعار عظمته وتطبيق أوامره واجتناب نواهيه.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: _currentBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: _currentAccentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _themeMode == MushafThemeMode.night ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تفسير الآية الكريمة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _currentAccentColor,
                    ),
                  ),
                  Text(
                    'سورة $surahName • آية ${toArabicDigits(ayah.id)}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _currentTextColor.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _themeMode == MushafThemeMode.night ? Colors.white.withValues(alpha: 0.05) : Colors.white60,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _currentBorderColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  '﴿ ${ayah.text} ﴾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.8,
                    color: _currentTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _themeMode == MushafThemeMode.night ? Colors.white.withValues(alpha: 0.04) : Colors.white70,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _currentAccentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 18,
                              color: _currentAccentColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'التفسير الميسر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _currentAccentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tafsirText,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            height: 1.8,
                            color: _currentTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.copy_rounded, size: 17, color: _currentAccentColor),
                      label: Text(
                        'نسخ التفسير',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: _currentAccentColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _currentAccentColor.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: '﴿ ${ayah.text} ﴾\n\nتفسير الآية:\n$tafsirText',
                        ));
                        AppSnackBar.showSuccess(context, 'تم نسخ تفسير الآية بنجاح');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 17),
                      label: const Text(
                        'مشاركة التفسير',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentAccentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        QuranShareComposerDialog.show(
                          context,
                          surahId: surahId,
                          surahName: surahName,
                          initialStartAyah: ayah.id,
                          initialEndAyah: ayah.id,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildAyahSheetActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    final borderColor = isHighlighted
        ? (_isNightMode ? AppColors.accentGold.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.35))
        : (_isNightMode ? Colors.white.withValues(alpha: 0.1) : paperBorder.withValues(alpha: 0.8));
    final bgColor = isHighlighted
        ? (_isNightMode ? AppColors.accentGold.withValues(alpha: 0.12) : AppColors.primary.withValues(alpha: 0.08))
        : (_isNightMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.85));
    final iconColor = isHighlighted
        ? (_isNightMode ? AppColors.accentGoldLight : AppColors.primary)
        : (_isNightMode ? AppColors.accentGoldLight : AppColors.primary);
    final textColor = _isNightMode ? nightText : textDark;

    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const List<({int juz, String name, String opening, int page})> _ajzaaList = [
    (juz: 1, name: 'الجزء الأول', opening: 'سورة الفاتحة', page: 1),
    (juz: 2, name: 'الجزء الثاني', opening: 'سَيَقُولُ ٱلسُّفَهَاءُ', page: 22),
    (juz: 3, name: 'الجزء الثالث', opening: 'تِلْكَ ٱلرُّسُلُ فَضَّلْنَا', page: 42),
    (juz: 4, name: 'الجزء الرابع', opening: 'كُلُّ ٱلطَّعَامِ كَانَ حِلّاً', page: 62),
    (juz: 5, name: 'الجزء الخامس', opening: 'وَٱلْمُحْصَنَاتُ مِنَ ٱلنِّسَاءِ', page: 82),
    (juz: 6, name: 'الجزء السادس', opening: 'لَا يُحِبُّ ٱللَّهُ ٱلْجَهْرَ', page: 102),
    (juz: 7, name: 'الجزء السابع', opening: 'لَتَجِدَنَّ أَشَدَّ ٱلنَّاسِ', page: 122),
    (juz: 8, name: 'الجزء الثامن', opening: 'وَلَوْ أَنَّنَا نَزَّلْنَآ إِلَيْهِمُ', page: 142),
    (juz: 9, name: 'الجزء التاسع', opening: 'قَالَ ٱلْمَلَأُ ٱلَّذِينَ ٱسْتَكْبَرُوا', page: 162),
    (juz: 10, name: 'الجزء العاشر', opening: 'وَٱعْلَمُوٓا أَنَّمَا غَنِمْتُم', page: 182),
    (juz: 11, name: 'الجزء الحادي عشر', opening: 'إِنَّمَا ٱلسَّبِيلُ عَلَى ٱلَّذِينَ', page: 202),
    (juz: 12, name: 'الجزء الثاني عشر', opening: 'وَمَا مِن دَآبَّةٍ فِي ٱلْأَرْضِ', page: 222),
    (juz: 13, name: 'الجزء الثالث عشر', opening: 'وَمَآ أُبَرِّئُ نَفْسِي', page: 242),
    (juz: 14, name: 'الجزء الرابع عشر', opening: 'رُبَمَا يَوَدُّ ٱلَّذِينَ كَفَرُوا', page: 262),
    (juz: 15, name: 'الجزء الخامس عشر', opening: 'سُبْحَانَ ٱلَّذِيٓ أَسْرَىٰ', page: 282),
    (juz: 16, name: 'الجزء السادس عشر', opening: 'قَالَ أَلَمْ أَقُل لَّكَ', page: 302),
    (juz: 17, name: 'الجزء السابع عشر', opening: 'ٱقْتَرَبَ لِلنَّاسِ حِسَابُهُمْ', page: 322),
    (juz: 18, name: 'الجزء الثامن عشر', opening: 'قَدْ أَفْلَحَ ٱلْمُؤْمِنُونَ', page: 342),
    (juz: 19, name: 'الجزء التاسع عشر', opening: 'وَقَالَ ٱلَّذِينَ لَا يَرْجُونَ', page: 362),
    (juz: 20, name: 'الجزء العشرون', opening: 'فَمَا كَانَ جَوَابَ قَوْمِهِۦ', page: 382),
    (juz: 21, name: 'الجزء الحادي والعشرون', opening: 'وَلَا تُجَادِلُوٓا أَهْلَ ٱلْكِتَابِ', page: 402),
    (juz: 22, name: 'الجزء الثاني والعشرون', opening: 'وَمَن يَقْنُتْ مِنكُنَّ', page: 422),
    (juz: 23, name: 'الجزء الثالث والعشرون', opening: 'وَمَآ أَنزَلْنَا عَلَىٰ قَوْمِهِ', page: 442),
    (juz: 24, name: 'الجزء الرابع والعشرون', opening: 'فَمَنْ أَظْلَمُ مِمَّن كَذَبَ', page: 462),
    (juz: 25, name: 'الجزء الخامس والعشرون', opening: 'إِلَيْهِ يُرَدُّ عِلْمُ ٱلسَّاعَةِ', page: 482),
    (juz: 26, name: 'الجزء السادس والعشرون', opening: 'حمٓ • تَنزِيلُ ٱلْكِتَابِ', page: 502),
    (juz: 27, name: 'الجزء السابع والعشرون', opening: 'قَالَ فَمَا خَطْبُكُمْ', page: 522),
    (juz: 28, name: 'الجزء الثامن والعشرون', opening: 'قَدْ سَمِعَ ٱللَّهُ قَوْلَ', page: 542),
    (juz: 29, name: 'الجزء التاسع والعشرون', opening: 'تَبَارَكَ ٱلَّذِي بِيَدِهِ ٱلْمُلْكُ', page: 562),
    (juz: 30, name: 'الجزء الثلاثون', opening: 'عَمَّ يَتَسَآءَلُونَ', page: 582),
  ];

  static const List<({String id, String name, Color color, String hex})> _ribbonColors = [
    (id: 'gold', name: 'العلامة الذهبية', color: Color(0xFFE5A93C), hex: '#E5A93C'),
    (id: 'green', name: 'العلامة الخضراء', color: Color(0xFF2E7D32), hex: '#2E7D32'),
    (id: 'blue', name: 'العلامة الزرقاء', color: Color(0xFF1E88E5), hex: '#1E88E5'),
    (id: 'pink', name: 'العلامة الوردية', color: Color(0xFFD81B60), hex: '#D81B60'),
  ];

  /// 3. Unified Quick Navigation Sheet (فهرس المصحف السريع: السور • الأجزاء • الصفحات)
  void _showQuickIndexSheet(BuildContext context, {int initialTabIndex = 0}) {
    final repo = context.read<QuranRepository>();
    final surahs = repo.cachedSurahs ?? [];
    final currentJuz = repo.getPage(_currentPage)?.juz ?? widget.surah.juz;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DefaultTabController(
        length: 3,
        initialIndex: initialTabIndex.clamp(0, 2),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final pageInputController = TextEditingController(text: _currentPage.toString());
            String surahSearchQuery = '';

            return Material(
              color: _currentBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.82,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: _currentAccentColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
                child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _themeMode == MushafThemeMode.night ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'فهرس المصحف الشريف',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _currentAccentColor,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 20, color: _currentAccentColor),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Modern Tab Bar
                    Container(
                      decoration: BoxDecoration(
                        color: _themeMode == MushafThemeMode.night
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: _currentAccentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _currentAccentColor.withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        labelColor: _currentAccentColor,
                        unselectedLabelColor: _currentTextColor.withValues(alpha: 0.65),
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
                        tabs: const [
                          Tab(text: 'السور'),
                          Tab(text: 'الأجزاء'),
                          Tab(text: 'الصفحات'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          // ── Tab 1: السور ──
                          StatefulBuilder(
                            builder: (context, setSurahTabState) {
                              final filteredSurahs = surahSearchQuery.isEmpty
                                  ? surahs
                                  : surahs.where((s) {
                                      final nameMatch = s.name.contains(surahSearchQuery.trim());
                                      final idMatch = s.id.toString() == surahSearchQuery.trim();
                                      return nameMatch || idMatch;
                                    }).toList();

                              return Column(
                                children: [
                                  // Search Field
                                  Container(
                                    height: 40,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'ابحث عن سورة بالاسم أو الرقم...',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12.5,
                                          color: _currentTextColor.withValues(alpha: 0.45),
                                        ),
                                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: _currentAccentColor),
                                        filled: true,
                                        fillColor: _themeMode == MushafThemeMode.night
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.white.withValues(alpha: 0.8),
                                        contentPadding: EdgeInsets.zero,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: _currentBorderColor.withValues(alpha: 0.6),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(
                                            color: _currentBorderColor.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 13,
                                        color: _currentTextColor,
                                      ),
                                      onChanged: (val) {
                                        setSurahTabState(() => surahSearchQuery = val);
                                      },
                                    ),
                                  ),
                                  // Surahs List
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: filteredSurahs.length,
                                      separatorBuilder: (_, __) => Divider(
                                        height: 1,
                                        color: _currentBorderColor.withValues(alpha: 0.3),
                                      ),
                                      itemBuilder: (context, idx) {
                                        final s = filteredSurahs[idx];
                                        final isCurrentSurah = s.startPage <= _currentPage &&
                                            (idx == filteredSurahs.length - 1 ||
                                                _currentPage < filteredSurahs[idx + 1].startPage);

                                        return ListTile(
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                          tileColor: isCurrentSurah
                                              ? _currentAccentColor.withValues(alpha: 0.12)
                                              : null,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          leading: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isCurrentSurah ? _currentAccentColor : _currentBorderColor,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                toArabicDigits(s.id),
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: _currentAccentColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            'سورة ${s.name}',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 14.5,
                                              fontWeight: isCurrentSurah ? FontWeight.bold : FontWeight.w600,
                                              color: _currentTextColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${s.type} • ${toArabicDigits(s.totalVerses)} آيات',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: 11,
                                              color: _currentTextColor.withValues(alpha: 0.55),
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _currentAccentColor.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'صفحة ${toArabicDigits(s.startPage)}',
                                              style: TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: _currentAccentColor,
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _pageController.jumpToPage(s.startPage - 1);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          // ── Tab 2: الأجزاء ──
                          ListView.separated(
                            itemCount: _ajzaaList.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: _currentBorderColor.withValues(alpha: 0.3),
                            ),
                            itemBuilder: (context, idx) {
                              final item = _ajzaaList[idx];
                              final isCurrent = item.juz == currentJuz;

                              return ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                tileColor: isCurrent ? _currentAccentColor.withValues(alpha: 0.12) : null,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCurrent ? _currentAccentColor : _currentBorderColor,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      toArabicDigits(item.juz),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _currentAccentColor,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14.5,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                    color: _currentTextColor,
                                  ),
                                ),
                                subtitle: Text(
                                  item.opening,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    color: _currentTextColor.withValues(alpha: 0.6),
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _currentAccentColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'صفحة ${toArabicDigits(item.page)}',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: _currentAccentColor,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _pageController.jumpToPage(item.page - 1);
                                },
                              );
                            },
                          ),

                          // ── Tab 3: الصفحات ──
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            child: Column(
                              children: [
                                // Current page hero card
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _themeMode == MushafThemeMode.night
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.white.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _currentBorderColor),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'أنت الآن في صفحة',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 12,
                                          color: _currentTextColor.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '﴿ ${toArabicDigits(_currentPage)} ﴾',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: _currentAccentColor,
                                        ),
                                      ),
                                      Text(
                                        'من إجمالي ٦٠٤ صفحة',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 11,
                                          color: _currentTextColor.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Numeric jump input
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: pageInputController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _currentTextColor,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'رقم الصفحة (١ - ٦٠٤)',
                                          labelStyle: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: _currentTextColor.withValues(alpha: 0.6),
                                          ),
                                          filled: true,
                                          fillColor: _themeMode == MushafThemeMode.night
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: _currentBorderColor),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _currentAccentColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        final target = int.tryParse(pageInputController.text.trim());
                                        if (target != null && target >= 1 && target <= 604) {
                                          Navigator.pop(ctx);
                                          _pageController.jumpToPage(target - 1);
                                        } else {
                                          AppSnackBar.showError(context, 'يرجى إدخال رقم صفحة صحيح بين ١ و ٦٠٤');
                                        }
                                      },
                                      child: const Text(
                                        'انتقال',
                                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Quick step navigation buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildStepJumpButton('-١٠', () {
                                      final p = (_currentPage - 10).clamp(1, 604);
                                      Navigator.pop(ctx);
                                      _pageController.jumpToPage(p - 1);
                                    }),
                                    _buildStepJumpButton('-١', () {
                                      final p = (_currentPage - 1).clamp(1, 604);
                                      Navigator.pop(ctx);
                                      _pageController.jumpToPage(p - 1);
                                    }),
                                    _buildStepJumpButton('+١', () {
                                      final p = (_currentPage + 1).clamp(1, 604);
                                      Navigator.pop(ctx);
                                      _pageController.jumpToPage(p - 1);
                                    }),
                                    _buildStepJumpButton('+١٠', () {
                                      final p = (_currentPage + 10).clamp(1, 604);
                                      Navigator.pop(ctx);
                                      _pageController.jumpToPage(p - 1);
                                    }),
                                  ],
                                ),
                                const Spacer(),

                                // Fast page slider
                                Slider(
                                  value: _currentPage.toDouble(),
                                  min: 1.0,
                                  max: 604.0,
                                  activeColor: _currentAccentColor,
                                  inactiveColor: _currentBorderColor.withValues(alpha: 0.4),
                                  onChanged: (val) {
                                    final p = val.round().clamp(1, 604);
                                    _pageController.jumpToPage(p - 1);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        ),
      ),
    );
  }

  Widget _buildStepJumpButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: _currentAccentColor,
        side: BorderSide(color: _currentBorderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  /// 5. Color-Coded Bookmark Ribbon Picker (الفواصل الملونة: ذهبي، أخضر، أزرق، وردي)
  void _showBookmarkRibbonPicker(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final currentPageData = repo.getPage(_currentPage);
    final qState = context.read<QuranBloc>().state;

    BookmarkModel? currentRibbon;
    if (qState is QuranLoaded) {
      for (final b in qState.richBookmarks) {
        if (b.pageNumber == _currentPage) {
          currentRibbon = b;
          break;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: _currentBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: _currentAccentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _themeMode == MushafThemeMode.night ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'فواصل المصحف الشريف الملونة',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _currentAccentColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'صفحة ${toArabicDigits(_currentPage)} • ضع فاصلاً للرجوع إليه لاحقاً',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: _currentTextColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),

              // The 4 Ribbons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _ribbonColors.map((ribbon) {
                  final isThisColorActive = currentRibbon != null && currentRibbon.color == ribbon.hex;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (currentPageData != null && currentPageData.segments.isNotEmpty) {
                        final seg = currentPageData.segments.first;
                        final v = seg.verses.first;

                        final newBookmark = BookmarkModel(
                          id: '${seg.surahId}:${v.id}',
                          ayahId: v.id,
                          surahId: seg.surahId,
                          ayahNumber: v.id,
                          pageNumber: _currentPage,
                          color: ribbon.hex,
                          note: 'فاصل ${ribbon.name}',
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        context.read<QuranBloc>().add(SaveRichBookmarkEvent(newBookmark));
                        AppSnackBar.showSuccess(
                          context,
                          'تم وضع ${ribbon.name} عند صفحة ${toArabicDigits(_currentPage)}',
                        );
                      }
                    },
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: ribbon.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isThisColorActive ? ribbon.color : ribbon.color.withValues(alpha: 0.35),
                          width: isThisColorActive ? 2.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isThisColorActive ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: ribbon.color,
                            size: 32,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ribbon.name.replaceFirst('العلامة ', ''),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: ribbon.color,
                            ),
                          ),
                          if (isThisColorActive) ...[
                            const SizedBox(height: 3),
                            Icon(Icons.check_circle_rounded, size: 14, color: ribbon.color),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (currentRibbon != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_remove_rounded, color: Colors.redAccent, size: 18),
                    label: const Text(
                      'إزالة الفاصل من هذه الصفحة',
                      style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (currentRibbon != null) {
                        context.read<QuranBloc>().add(
                              DeleteRichBookmarkEvent(currentRibbon.surahId, currentRibbon.ayahNumber),
                            );
                        AppSnackBar.showSuccess(context, 'تمت إزالة الفاصل بنجاح');
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }

  /// 6. Khatmah Tracker (متابع الختمة: تتبع التقدم، نسبة الختمة، وحفظ الموضع)
  void _showKhatmahTrackerSheet(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final checkpoint = repo.getKhatmahCheckpoint();
    int targetDays = repo.getKhatmahTargetDays();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final progressPercent = (_currentPage / 604.0).clamp(0.0, 1.0);
          final pagesRemaining = (604 - _currentPage).clamp(0, 604);
          final dailyGoal = (604 / targetDays).ceil();

          return Material(
            color: _currentBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: _currentAccentColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _themeMode == MushafThemeMode.night ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, color: _currentAccentColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'متابع الختمة القرآنية',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _currentAccentColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: _currentAccentColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Main Progress Display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _themeMode == MushafThemeMode.night
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _currentBorderColor.withValues(alpha: 0.7)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'صفحة ${toArabicDigits(_currentPage)} من ٦٠٤',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _currentTextColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _currentAccentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(progressPercent * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _currentAccentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            minHeight: 8,
                            backgroundColor: _currentBorderColor.withValues(alpha: 0.4),
                            color: _currentAccentColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildKhatmahStatChip('المنجز', '${toArabicDigits(_currentPage)} ص'),
                            _buildKhatmahStatChip('المتبقي', '${toArabicDigits(pagesRemaining)} ص'),
                            _buildKhatmahStatChip('الموضع المحفوظ', 'ص ${toArabicDigits(checkpoint)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Khatmah Goal Selector
                  Text(
                    'اختر خطة الختمة (المعدل المطلوب: ${toArabicDigits(dailyGoal)} صفحة يومياً):',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _currentTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPlanOption(
                        label: '٣٠ يوماً',
                        sub: '٢٠ ص/يوم',
                        isSelected: targetDays == 30,
                        onTap: () {
                          setSheetState(() => targetDays = 30);
                          repo.setKhatmahTargetDays(30);
                        },
                      ),
                      _buildPlanOption(
                        label: '٦٠ يوماً',
                        sub: '١٠ ص/يوم',
                        isSelected: targetDays == 60,
                        onTap: () {
                          setSheetState(() => targetDays = 60);
                          repo.setKhatmahTargetDays(60);
                        },
                      ),
                      _buildPlanOption(
                        label: '٩٠ يوماً',
                        sub: '٧ ص/يوم',
                        isSelected: targetDays == 90,
                        onTap: () {
                          setSheetState(() => targetDays = 90);
                          repo.setKhatmahTargetDays(90);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Action Button 1: Save checkpoint
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bookmark_added_rounded, size: 18),
                      label: Text(
                        'حفظ موضع الختمة عند صفحة ${toArabicDigits(_currentPage)}',
                        style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentAccentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        repo.setKhatmahCheckpoint(_currentPage);
                        AppSnackBar.showSuccess(
                          context,
                          'تم حفظ موضع الختمة عند صفحة ${toArabicDigits(_currentPage)} بنجاح',
                        );
                      },
                    ),
                  ),

                  // Action Button 2: Jump to saved checkpoint
                  if (checkpoint != _currentPage) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.arrow_forward_rounded, size: 18, color: _currentAccentColor),
                        label: Text(
                          'الانتقال إلى موضع الختمة المحفوظ (صفحة ${toArabicDigits(checkpoint)})',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            color: _currentAccentColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _currentAccentColor),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _pageController.jumpToPage(checkpoint - 1);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildKhatmahStatChip(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10.5,
            color: _currentTextColor.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _currentAccentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOption({
    required String label,
    required String sub,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _currentAccentColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _currentAccentColor : _currentBorderColor.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? _currentAccentColor : _currentTextColor,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: _currentTextColor.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Reading Themes Options (ثيمات ورق المصحف الثلاثة دون سلايدرز الخط الملغاة)
  void _showReaderOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Material(
            color: _currentBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: _currentAccentColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _themeMode == MushafThemeMode.night ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'ثيمات ورق المصحف الشريف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _currentAccentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختر لون ورق المصحف المريح لعينيك أثناء القراءة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: _currentTextColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3 Reading Theme Cards
                  Row(
                    children: [
                      // 1. Royal Ivory
                      _buildThemeCard(
                        title: 'عاجي ملكي',
                        subtitle: 'ورق المصحف الأصيل',
                        sampleBg: const Color(0xFFFAF6EE),
                        sampleBorder: const Color(0xFFC49A45),
                        sampleText: const Color(0xFF231F1B),
                        isSelected: _themeMode == MushafThemeMode.ivory,
                        onTap: () {
                          _setMushafTheme(MushafThemeMode.ivory);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(width: 8),

                      // 2. Antique Sepia
                      _buildThemeCard(
                        title: 'بيج تراثي',
                        subtitle: 'مريح للعينين نهاراً',
                        sampleBg: const Color(0xFFF3EBD9),
                        sampleBorder: const Color(0xFFB88E3E),
                        sampleText: const Color(0xFF2C2218),
                        isSelected: _themeMode == MushafThemeMode.sepia,
                        onTap: () {
                          _setMushafTheme(MushafThemeMode.sepia);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(width: 8),

                      // 3. Quiet Night
                      _buildThemeCard(
                        title: 'ليلي هادئ',
                        subtitle: 'قراءة ليلية بدون وهج',
                        sampleBg: const Color(0xFF121714),
                        sampleBorder: const Color(0xFF8A7135),
                        sampleText: const Color(0xFFECE8DF),
                        isSelected: _themeMode == MushafThemeMode.night,
                        onTap: () {
                          _setMushafTheme(MushafThemeMode.night);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick links: Tajweed Stop signs & Dua Khatm
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.menu_book_rounded, size: 17, color: _currentAccentColor),
                          label: Text(
                            'علامات الوقف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _currentAccentColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _currentAccentColor.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            MushafInfoSheets.showTajweedGuide(context, isDark: _themeMode == MushafThemeMode.night);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.auto_stories_rounded, size: 17, color: _currentAccentColor),
                          label: Text(
                            'دعاء الختم',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _currentAccentColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _currentAccentColor.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            MushafInfoSheets.showDuaKhatm(context, isDark: _themeMode == MushafThemeMode.night);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    required Color sampleBg,
    required Color sampleBorder,
    required Color sampleText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: sampleBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? sampleBorder : sampleBorder.withValues(alpha: 0.35),
              width: isSelected ? 2.2 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: sampleBorder.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: sampleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: sampleBorder, width: 1.2),
                ),
                child: Center(
                  child: isSelected
                      ? Icon(Icons.check_rounded, size: 16, color: sampleText)
                      : Text(
                          'ق',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: sampleText,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: sampleText,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 9,
                  color: sampleText.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compatibility delegates
  @visibleForTesting
  void showSurahPicker() => _showQuickIndexSheet(context, initialTabIndex: 0);

  @visibleForTesting
  void showJumpToPageDialog() => _showQuickIndexSheet(context, initialTabIndex: 2);

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final currentPageData = repo.getPage(_currentPage);
    final pageSurahName = currentPageData?.surahName ?? widget.surah.name;
    final pageJuz = currentPageData?.juz ?? widget.surah.juz;

    final bgColor = _currentBgColor;
    final pageCardColor = _currentBgColor;
    final bronze = _currentAccentColor;

    final qState = context.watch<QuranBloc>().state;
    BookmarkModel? pageBookmark;
    if (qState is QuranLoaded && currentPageData != null) {
      for (final b in qState.richBookmarks) {
        if (b.pageNumber == _currentPage) {
          pageBookmark = b;
          break;
        }
      }
    }
    final isPageBookmarked = pageBookmark != null ||
        (qState is QuranLoaded &&
            currentPageData != null &&
            currentPageData.segments.any(
              (seg) => seg.verses.any(
                (v) => qState.bookmarks.contains('${seg.surahId}:${v.id}'),
              ),
            ));
    final Color? ribbonColor = pageBookmark != null
        ? Color(int.parse(pageBookmark.color.replaceFirst('#', '0xFF')))
        : (isPageBookmarked ? const Color(0xFFE5A93C) : null);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: (_showControls || _isSelectionMode)
          ? AppBar(
              backgroundColor: pageCardColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 46,
              leadingWidth: 42,
              titleSpacing: 2,
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: _isNightMode ? Brightness.light : Brightness.dark,
                statusBarBrightness: _isNightMode ? Brightness.dark : Brightness.light,
              ),
              shape: Border(
                bottom: BorderSide(
                  color: _currentBorderColor.withValues(alpha: 0.45),
                  width: 0.6,
                ),
              ),
              leading: _isSelectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'إلغاء التحديد',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                      onPressed: _clearSelection,
                    )
                  : IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: bronze, size: 18),
                      tooltip: 'رجوع',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                      onPressed: () => Navigator.pop(context),
                    ),
              title: _isSelectionMode
                  ? Text(
                      'تم تحديد ${toArabicDigits(_selectedAyat.length)} آيات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: bronze,
                      ),
                    )
                  : InkWell(
                      onTap: () => _showQuickIndexSheet(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'سورة $pageSurahName',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: bronze,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '• الجزء ${toArabicDigits(pageJuz)}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: bronze.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              actions: _isSelectionMode
                  ? [
                      TextButton(
                        onPressed: _clearSelection,
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: bronze,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ]
                  : [
                      // 1. Quick Navigation Index (فهرس المصحف السريع)
                      IconButton(
                        icon: Icon(Icons.grid_view_rounded, color: bronze, size: 19),
                        tooltip: 'فهرس المصحف',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () => _showQuickIndexSheet(context),
                      ),
                      // 2. Khatmah Tracker (متابع الختمة)
                      IconButton(
                        icon: Icon(Icons.flag_outlined, color: bronze, size: 19),
                        tooltip: 'متابع الختمة',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () => _showKhatmahTrackerSheet(context),
                      ),
                      // 3. Reading Themes & Options (ثيمات ورق المصحف)
                      IconButton(
                        icon: Icon(Icons.tune_rounded, color: bronze, size: 19),
                        tooltip: 'ثيمات ورق المصحف',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: _showReaderOptionsMenu,
                      ),
                      // 4. Color-Coded Bookmark Ribbon (فواصل المصحف الملونة)
                      IconButton(
                        icon: Icon(
                          isPageBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: ribbonColor ?? bronze,
                          size: 20,
                        ),
                        tooltip: 'فواصل المصحف الملونة',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        onPressed: () => _showBookmarkRibbonPicker(context),
                      ),
                      const SizedBox(width: 4),
                    ],
            )
          : null,

      body: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: 604,
        onPageChanged: (pageIndex) {
          setState(() {
            _currentPage = pageIndex + 1;
            _highlightedAyahId = null;
            _highlightedSurahId = null;
          });
          _recordCurrentPageAsLastRead();
          QcfLayoutService.instance.loadPage(_currentPage);
          MushafImageService.instance.ensurePageImage(_currentPage);
        },
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final pageData = repo.getPage(pageNum);

          if (pageData == null) {
            return Center(
              child: CircularProgressIndicator(color: _currentAccentColor),
            );
          }

          return _buildMushafPage(pageData, pageNum);
        },
      ),

      // Bottom Bar is completely removed unless user activates multi-ayah selection mode
      bottomNavigationBar: _isSelectionMode
          ? _buildSelectionActionBar(pageCardColor, bronze)
          : null,
    );
  }

  Widget _buildSelectionActionBar(Color bgColor, Color bronze) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isNightMode ? const Color(0xFF141815) : Colors.white,
        border: Border(
          top: BorderSide(
            color: _isNightMode ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSelectionActionItem(
              icon: Icons.bookmark_add_rounded,
              label: 'حفظ',
              color: AppColors.accentGold,
              onTap: _bookmarkSelectedAyat,
            ),
            _buildSelectionActionItem(
              icon: Icons.share_rounded,
              label: 'مشاركة',
              color: _isNightMode ? Colors.tealAccent : Colors.teal[800]!,
              onTap: _shareSelectedAyat,
            ),
            _buildSelectionActionItem(
              icon: Icons.copy_rounded,
              label: 'نسخ',
              color: _isNightMode ? Colors.white70 : textDark,
              onTap: _copySelectedAyat,
            ),
            _buildSelectionActionItem(
              icon: Icons.close_rounded,
              label: 'إلغاء',
              color: Colors.redAccent,
              onTap: _clearSelection,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildAyahSpans({
    required MushafPageSegment segment,
    required AyahModel ayah,
    required Color textColor,
    required QuranState qState,
  }) {
    final key = '${segment.surahId}:${ayah.id}';
    final isSelected = _selectedAyat.containsKey(key);
    final isHighlighted = _highlightedAyahId == ayah.id && widget.surah.id == segment.surahId;
    final anyHighlighted = _highlightedAyahId != null;

    BookmarkModel? richBk;
    if (qState is QuranLoaded) {
      for (final b in qState.richBookmarks) {
        if (b.surahId == segment.surahId && b.ayahNumber == ayah.id) {
          richBk = b;
          break;
        }
      }
    }
    final isAyahBookmarked = richBk != null ||
        (qState is QuranLoaded && qState.bookmarks.contains(key));
    final bookmarkColor = richBk != null
        ? Color(int.parse(richBk.color.replaceFirst('#', '0xFF')))
        : const Color(0xFF2E7D32);

    final pageFontSize = 17.5 * (_fontSize / 24.0);

    Color currentTextColor;
    if (isSelected) {
      currentTextColor = _isNightMode ? AppColors.accentGoldLight : const Color(0xFF8C5D00);
    } else if (isHighlighted) {
      currentTextColor = _isNightMode ? const Color(0xFFFDE68A) : const Color(0xFF78350F);
    } else if (anyHighlighted) {
      currentTextColor = _isNightMode ? nightText.withValues(alpha: 0.55) : textColor.withValues(alpha: 0.65);
    } else {
      currentTextColor = textColor;
    }

    Color? currentBgColor;
    if (isSelected) {
      currentBgColor = AppColors.accentGold.withValues(alpha: 0.32);
    } else if (isHighlighted) {
      currentBgColor = AppColors.accentGold.withValues(alpha: _isNightMode ? 0.35 : 0.22);
    } else if (isAyahBookmarked) {
      currentBgColor = bookmarkColor.withValues(alpha: 0.12);
    }

    return [
      TextSpan(
        text: '${ayah.text} ',
        recognizer: AyahGestureRecognizer()
          ..onTap = () {
            _onAyahTap(
              surahId: segment.surahId,
              surahName: segment.surahName,
              ayah: ayah,
              page: ayah.page,
            );
          }
          ..onLongPress = () {
            _onAyahLongPress(
              surahId: segment.surahId,
              surahName: segment.surahName,
              ayah: ayah,
            );
          },
        style: TextStyle(
          fontFamily: 'UthmanicHafs',
          fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
          fontSize: pageFontSize,
          fontWeight: _computeFontWeight(),
          height: 1.95,
          color: currentTextColor,
          backgroundColor: currentBgColor,
          letterSpacing: 0.1,
        ),
      ),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        style: TextStyle(
          fontFamily: 'UthmanicHafs',
          fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
          fontSize: pageFontSize,
          fontWeight: _computeFontWeight(),
          height: 1.95,
          backgroundColor: currentBgColor,
        ),
        child: GestureDetector(
          onTap: () {
            _onAyahTap(
              surahId: segment.surahId,
              surahName: segment.surahName,
              ayah: ayah,
              page: ayah.page,
            );
          },
          onLongPress: () {
            _onAyahLongPress(
              surahId: segment.surahId,
              surahName: segment.surahName,
              ayah: ayah,
            );
          },
          child: Container(
            color: currentBgColor,
            padding: const EdgeInsets.symmetric(horizontal: 1.0),
            child: isSelected
                ? Container(
                    width: (pageFontSize * 1.15).clamp(20.0, 26.0),
                    height: (pageFontSize * 1.15).clamp(20.0, 26.0),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF1E1A17),
                      size: 14,
                    ),
                  )
                : AyahRosette(
                    ayahNumber: ayah.id,
                    size: (pageFontSize * 1.15).clamp(20.0, 26.0),
                    borderColor: isHighlighted
                        ? AppColors.accentGold
                        : (isAyahBookmarked
                            ? bookmarkColor
                            : (_isNightMode ? nightBronze : goldAccent)),
                    fillColor: isHighlighted
                        ? AppColors.accentGold.withValues(alpha: 0.3)
                        : (isAyahBookmarked
                            ? (_isNightMode
                                ? bookmarkColor.withValues(alpha: 0.25)
                                : bookmarkColor.withValues(alpha: 0.18))
                            : (_isNightMode
                                ? const Color(0xFF262C28)
                                : const Color(0xFFF6EEDB))),
                    textColor: isHighlighted
                        ? (_isNightMode ? const Color(0xFFFDE68A) : const Color(0xFF78350F))
                        : (_isNightMode ? nightText : const Color(0xFF4A341E)),
                    highlightBgColor: currentBgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  ),
          ),
        ),
      ),
    ];
  }

  Widget _buildMushafPage(MushafPageModel pageData, int pageNum) {
    final textColor = _isNightMode ? nightText : textDark;
    final isCenteredPage = pageNum <= 2;
    final qState = context.watch<QuranBloc>().state;
    final bronze = _isNightMode ? nightBronze : bronzeAccent;
    final repo = context.read<QuranRepository>();

    return FutureBuilder<QcfPageModel?>(
      future: QcfLayoutService.instance.loadPage(pageNum),
      initialData: QcfLayoutService.instance.getCachedPage(pageNum),
      builder: (context, snapshot) {
        final qcfPage = snapshot.data;
        if (qcfPage != null) {
          return QcfMushafPageRenderer(
            pageModel: qcfPage,
            isNightMode: _isNightMode,
            themeMode: _themeMode,
            highlightedAyahId: _highlightedAyahId,
            highlightedSurahId: _highlightedSurahId,
            selectedAyat: _selectedAyat,
            bookmarks: qState is QuranLoaded ? qState.bookmarks : const {},
            richBookmarks: qState is QuranLoaded ? qState.richBookmarks : const [],
            juz: pageData.juz,
            hizb: pageData.hizb,
            surahName: pageData.surahName,
            onAyahTap: ({required int surahId, required int ayahId}) {
              final surah = repo.getSurahById(surahId);
              if (surah == null) return;
              final ayah = surah.verses.firstWhere(
                (v) => v.id == ayahId,
                orElse: () => surah.verses.first,
              );
              _onAyahTap(
                surahId: surahId,
                surahName: surah.name,
                ayah: ayah,
                page: pageNum,
              );
            },
            onAyahLongPress: ({required int surahId, required int ayahId}) {
              final surah = repo.getSurahById(surahId);
              if (surah == null) return;
              final ayah = surah.verses.firstWhere(
                (v) => v.id == ayahId,
                orElse: () => surah.verses.first,
              );
              _onAyahLongPress(
                surahId: surahId,
                surahName: surah.name,
                ayah: ayah,
              );
            },
            onPageTap: () {
              // Keep top & bottom bars permanently visible.
              // Tapping the page clears any highlighted ayah.
              if (_highlightedAyahId != null) {
                setState(() {
                  _highlightedAyahId = null;
                  _highlightedSurahId = null;
                });
              }
            },
            onPreviousPage: () {
              if (_currentPage > 1) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                );
              }
            },
            onNextPage: () {
              if (_currentPage < 604) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                );
              }
            },
          );
        }

        return _buildLegacyMushafPage(pageData, pageNum, textColor, isCenteredPage, qState, bronze);
      },
    );
  }

  Widget _buildLegacyMushafPage(
    MushafPageModel pageData,
    int pageNum,
    Color textColor,
    bool isCenteredPage,
    QuranState qState,
    Color bronze,
  ) {
    final bgPaper = _isNightMode ? nightPaper : paperBg;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_highlightedAyahId != null) {
                setState(() {
                  _highlightedAyahId = null;
                  _highlightedSurahId = null;
                });
              }
            },
            child: Container(
              color: bgPaper,
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: kMushafAspectRatio,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: kMushafPageWidth,
                    height: kMushafPageHeight,
                    child: _buildMushafPageContent(
                      pageData: pageData,
                      pageNum: pageNum,
                      textColor: textColor,
                      isCenteredPage: isCenteredPage,
                      qState: qState,
                      bronze: bronze,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Tap LEFT edge → previous page
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_currentPage > 1) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
        // Tap RIGHT edge → next page
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_currentPage < 604) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  /// Builds the actual content of the fixed Mushaf page canvas.
  /// This runs on a rigid 385 x 620 logical canvas and is scaled proportionally by FittedBox.
  Widget _buildMushafPageContent({
    required MushafPageModel pageData,
    required int pageNum,
    required Color textColor,
    required bool isCenteredPage,
    required QuranState qState,
    required Color bronze,
  }) {
    final bgPaper = _isNightMode ? nightPaper : paperBg;

    return Container(
      color: bgPaper,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: In-Page Surah Name + Juz + Ornamental Divider ──────────
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInPageHeader(pageData, bronze),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: CustomPaint(
                  size: const Size(double.infinity, 2),
                  painter: _GoldenLinePainter(
                    color: goldAccent.withValues(alpha: _isNightMode ? 0.5 : 0.4),
                  ),
                ),
              ),
            ],
          ),

          // ── Center Reading Body: Surah Banners + Deterministic Verses ──────
          Expanded(
            child: Container(
              alignment: isCenteredPage ? Alignment.center : Alignment.topCenter,
              padding: EdgeInsets.symmetric(
                vertical: isCenteredPage ? 20.0 : 2.0,
                horizontal: isCenteredPage ? 14.0 : 0.0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: isCenteredPage ? Alignment.center : Alignment.topCenter,
                child: SizedBox(
                  width: kMushafPageWidth - 32.0, // Fixed 353.0 reading width
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final segment in pageData.segments) ...[
                        // Surah Header Banner
                        if (segment.startsSurah)
                          _buildCompactSurahHeader(segment, pageData.juz),

                        // Bismillah calligraphic header
                        if (segment.startsSurah &&
                            segment.surahId != 1 &&
                            segment.surahId != 9)
                          _buildCompactBismillah(),

                        // Ayah text spans
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                for (final ayah in segment.verses)
                                  ..._buildAyahSpans(
                                    segment: segment,
                                    ayah: ayah,
                                    textColor: textColor,
                                    qState: qState,
                                  ),
                              ],
                            ),
                            textAlign: isCenteredPage
                                ? TextAlign.center
                                : TextAlign.justify,
                            textDirection: TextDirection.rtl,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Footer: Ornamental Divider + Page Number ───────────────────────
          _buildInPageFooter(pageData, bronze),
        ],
      ),
    );
  }

  /// Compact two-line header inside the Mushaf canvas (not the AppBar)
  Widget _buildInPageHeader(MushafPageModel pageData, Color bronze) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'سُورَةُ ${pageData.surahName}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: bronze.withValues(alpha: 0.9),
            ),
          ),
          Text(
            'الجزء ${toArabicDigits(pageData.juz)}',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: bronze.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  /// Page number footer inside the Mushaf canvas
  Widget _buildInPageFooter(MushafPageModel pageData, Color bronze) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Column(
        children: [
          CustomPaint(
            size: const Size(double.infinity, 2),
            painter: _GoldenLinePainter(
              color: goldAccent.withValues(alpha: _isNightMode ? 0.5 : 0.4),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            toArabicDigits(pageData.pageNumber),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: bronze.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Surah header inside the fixed canvas (smaller than the full MushafSurahBanner)
  Widget _buildCompactSurahHeader(MushafPageSegment segment, int juz) {
    final bgCard = _isNightMode ? const Color(0xFF1E2420) : const Color(0xFFFBF8F0);
    final cartoucheBg = _isNightMode ? const Color(0xFF262E2A) : const Color(0xFFF6F0E4);
    const goldColor = Color(0xFFB89368);
    const bronzeColor = Color(0xFF8C643E);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      height: 36,
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: goldColor.withValues(alpha: 0.75), width: 1.2),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BannerOrnamentsPainter(
                color: goldColor.withValues(alpha: _isNightMode ? 0.30 : 0.40),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 2),
              decoration: BoxDecoration(
                color: cartoucheBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: bronzeColor.withValues(alpha: 0.65),
                  width: 1.0,
                ),
              ),
              child: Text(
                'سُورَةُ ${segment.surahName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _isNightMode ? const Color(0xFFE8D7B8) : const Color(0xFF4A341E),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact Bismillah for inside the fixed-canvas page
  Widget _buildCompactBismillah() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Text(
        'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'UthmanicHafs',
          fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
          fontSize: _fontSize * 0.85,
          fontWeight: _computeFontWeight(),
          color: _isNightMode ? nightBronze : bronzeAccent,
          height: 1.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters reused inside the fixed canvas
// ─────────────────────────────────────────────────────────────────────────────

class _GoldenLinePainter extends CustomPainter {
  final Color color;

  _GoldenLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Decorative diamond dots at ends
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(4, 1), 1.5, dotPaint);
    canvas.drawCircle(Offset(size.width - 4, 1), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _GoldenLinePainter old) => old.color != color;
}

/// Banner ornaments painter (reused from MushafSurahBanner)
class _BannerOrnamentsPainter extends CustomPainter {
  final Color color;

  _BannerOrnamentsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawRect(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4), paint);

    const c = 10.0;
    // Corners
    canvas.drawLine(const Offset(4, 4), const Offset(4 + c, 4), paint);
    canvas.drawLine(const Offset(4, 4), const Offset(4, 4 + c), paint);
    canvas.drawLine(Offset(4, size.height - 4), Offset(4 + c, size.height - 4), paint);
    canvas.drawLine(Offset(4, size.height - 4), Offset(4, size.height - 4 - c), paint);
    canvas.drawLine(Offset(size.width - 4, 4), Offset(size.width - 4 - c, 4), paint);
    canvas.drawLine(Offset(size.width - 4, 4), Offset(size.width - 4, 4 + c), paint);
    canvas.drawLine(Offset(size.width - 4, size.height - 4), Offset(size.width - 4 - c, size.height - 4), paint);
    canvas.drawLine(Offset(size.width - 4, size.height - 4), Offset(size.width - 4, size.height - 4 - c), paint);
  }

  @override
  bool shouldRepaint(covariant _BannerOrnamentsPainter old) => old.color != color;
}

/// Custom GestureRecognizer for individual Ayah spans.
/// Handles both single Tap and Long-Press (holding for 500ms).
/// Naturally rejects gestures if the user swipes/scrolls to turn pages.
class AyahGestureRecognizer extends LongPressGestureRecognizer {
  VoidCallback? onTap;
  bool _longPressFired = false;

  AyahGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
  });

  @override
  void didExceedDeadline() {
    _longPressFired = true;
    resolve(GestureDisposition.accepted);
    onLongPress?.call();
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      if (!_longPressFired) {
        resolve(GestureDisposition.accepted);
        onTap?.call();
      }
      _longPressFired = false;
    } else if (event is PointerCancelEvent) {
      resolve(GestureDisposition.rejected);
      _longPressFired = false;
    } else if (event is PointerDownEvent) {
      _longPressFired = false;
    }
  }

  @override
  String get debugDescription => 'AyahGestureRecognizer';
}



