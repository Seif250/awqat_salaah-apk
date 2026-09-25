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

class SurahDetailPage extends StatefulWidget {
  final SurahModel surah;
  final int initialAyah;

  const SurahDetailPage({
    super.key,
    required this.surah,
    this.initialAyah = 1,
  });

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  late final PageController _pageController;
  late int _currentPage;
  int? _highlightedAyahId;
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

  // Authentic Medina Mushaf Colors from User's Reference Screenshots
  static const Color paperBg = Color(0xFFFAF7EE);
  static const Color paperBorder = Color(0xFFDFD4C0);
  static const Color textDark = Color(0xFF1E1A17);
  static const Color bronzeAccent = Color(0xFF7A583A);
  static const Color goldAccent = Color(0xFFB89368);

  // Night Mode Alternatives
  static const Color nightPaper = Color(0xFF1B201D);
  static const Color nightText = Color(0xFFE8E5DD);
  static const Color nightBronze = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    final repo = context.read<QuranRepository>();
    final targetPage = repo.getPageForAyah(widget.surah.id, widget.initialAyah);
    _currentPage = targetPage.clamp(1, 604);
    _pageController = PageController(initialPage: _currentPage - 1);
    _highlightedAyahId = widget.initialAyah >= 1 ? widget.initialAyah : null;

    final qState = context.read<QuranBloc>().state;
    if (qState is QuranLoaded) {
      _fontSize = qState.fontSize;
      _fontWeightValue = qState.fontWeightValue;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordCurrentPageAsLastRead();
    });
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

  String _fontWeightLabel() {
    if (_fontWeightValue <= 0.0) return 'عادي';
    if (_fontWeightValue <= 0.25) return 'متوسط';
    if (_fontWeightValue <= 0.50) return 'سميك';
    if (_fontWeightValue <= 0.75) return 'عريض';
    return 'أعرض';
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
      _showAyahActions(surahId, surahName, ayah);
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
    setState(() => _highlightedAyahId = ayah.id);

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
        setState(() => _highlightedAyahId = null);
      }
    });
  }

  void _showTafsirSheet(BuildContext context, int surahId, String surahName, AyahModel ayah) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.70,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: _isNightMode ? nightPaper : paperBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: _isNightMode ? nightBronze : goldAccent,
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
                  color: _isNightMode ? Colors.white24 : Colors.black12,
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
                      color: _isNightMode ? nightBronze : bronzeAccent,
                    ),
                  ),
                  Text(
                    'سورة $surahName • آية ${toArabicDigits(ayah.id)}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isNightMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isNightMode ? Colors.black26 : Colors.white60,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isNightMode ? Colors.white12 : paperBorder,
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
                    color: _isNightMode ? nightText : textDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isNightMode ? Colors.black12 : Colors.white70,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (_isNightMode ? nightBronze : goldAccent).withValues(alpha: 0.2),
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
                              color: _isNightMode ? nightBronze : bronzeAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'التفسير الميسر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isNightMode ? nightBronze : bronzeAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'قوله تعالى في سورة $surahName، الآية ${toArabicDigits(ayah.id)}:\n'
                          '﴿ ${ayah.text} ﴾\n\n'
                          'هذه الآية الكريمة من كتاب الله المحكم، تبيّن معالم الهداية ودلائل الإيمان، وتدعو المؤمن للتدبر في كلام رب العالمين واستشعار عظمته وتطبيق أوامره واجتناب نواهيه.',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            height: 1.8,
                            color: _isNightMode ? nightText : textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'مشاركة الآية مع التفسير',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isNightMode ? nightBronze : bronzeAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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

  void _showSurahPicker() {
    final repo = context.read<QuranRepository>();
    final surahs = repo.cachedSurahs ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(
          color: _isNightMode ? nightPaper : paperBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: _isNightMode ? nightBronze : goldAccent,
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
                  color: _isNightMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'فهرس سور القرآن الكريم',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _isNightMode ? nightBronze : bronzeAccent,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: surahs.length,
                  itemBuilder: (context, idx) {
                    final s = surahs[idx];
                    final isCurrent = s.name == repo.getPage(_currentPage)?.surahName;

                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isCurrent
                          ? (_isNightMode ? nightBronze.withValues(alpha: 0.2) : goldAccent.withValues(alpha: 0.15))
                          : null,
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isNightMode ? nightBronze : goldAccent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            toArabicDigits(s.id),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isNightMode ? nightBronze : bronzeAccent,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'سورة ${s.name}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isNightMode ? nightText : textDark,
                        ),
                      ),
                      subtitle: Text(
                        '${s.type} • صفحة ${toArabicDigits(s.startPage)}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: _isNightMode ? Colors.white54 : Colors.black54,
                        ),
                      ),
                      trailing: Text(
                        'الجزء ${toArabicDigits(s.juz)}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: _isNightMode ? nightBronze : bronzeAccent,
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
          ),
        ),
      ),
    );
  }

  void _showJumpToPageDialog() {
    final textController = TextEditingController(text: _currentPage.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isNightMode ? nightPaper : paperBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _isNightMode ? nightBronze : goldAccent),
        ),
        title: Text(
          'الانتقال إلى صفحة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: _isNightMode ? nightBronze : bronzeAccent,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'أدخل رقم الصفحة من ١ إلى ٦٠٤',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isNightMode ? nightText : textDark,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: _isNightMode ? Colors.black26 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: _isNightMode ? nightBronze : goldAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isNightMode ? nightBronze : bronzeAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final pageNum = int.tryParse(textController.text.trim());
              if (pageNum != null && pageNum >= 1 && pageNum <= 604) {
                Navigator.pop(ctx);
                _pageController.jumpToPage(pageNum - 1);
              }
            },
            child: const Text('انتقال', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReaderOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: _isNightMode ? nightPaper : paperBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: _isNightMode ? nightBronze : goldAccent,
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
                        color: _isNightMode ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خيارات عرض المصحف',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _isNightMode ? nightBronze : bronzeAccent,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Night / Paper mode switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isNightMode ? Colors.black26 : Colors.white60,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isNightMode ? Colors.white12 : paperBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isNightMode ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                              color: _isNightMode ? nightBronze : bronzeAccent,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isNightMode ? 'الوضع الليلي' : 'لون الورق الطبيعي',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isNightMode ? nightText : textDark,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isNightMode,
                          activeThumbColor: nightBronze,
                          activeTrackColor: Colors.black45,
                          onChanged: (val) {
                            setState(() => _isNightMode = val);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Font size slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_size_rounded,
                            size: 20,
                            color: _isNightMode ? nightBronze : bronzeAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'حجم الخط',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isNightMode ? nightText : textDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: (_isNightMode ? nightBronze : bronzeAccent).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          toArabicDigits(_fontSize.round()),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isNightMode ? nightBronze : bronzeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _isNightMode ? nightBronze : bronzeAccent,
                      inactiveTrackColor: _isNightMode ? Colors.white12 : Colors.black12,
                      thumbColor: _isNightMode ? nightBronze : bronzeAccent,
                    ),
                    child: Slider(
                      value: _fontSize,
                      min: 18.0,
                      max: 34.0,
                      divisions: 8,
                      onChanged: (val) {
                        setState(() => _fontSize = val);
                        setSheetState(() {});
                        context.read<QuranBloc>().add(ChangeFontSizeEvent(val));
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Font weight slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_bold_rounded,
                            size: 20,
                            color: _isNightMode ? nightBronze : bronzeAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'سمك الخط',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _isNightMode ? nightText : textDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: (_isNightMode ? nightBronze : bronzeAccent).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _fontWeightLabel(),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isNightMode ? nightBronze : bronzeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _isNightMode ? nightBronze : bronzeAccent,
                      inactiveTrackColor: _isNightMode ? Colors.white12 : Colors.black12,
                      thumbColor: _isNightMode ? nightBronze : bronzeAccent,
                    ),
                    child: Slider(
                      value: _fontWeightValue,
                      min: 0.0,
                      max: 1.0,
                      divisions: 4,
                      onChanged: (val) {
                        setState(() => _fontWeightValue = val);
                        setSheetState(() {});
                        context.read<QuranBloc>().add(ChangeFontWeightEvent(val));
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Preview text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isNightMode ? Colors.black26 : Colors.white60,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isNightMode ? Colors.white12 : paperBorder,
                      ),
                    ),
                    child: Text(
                      'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'UthmanicHafs',
                        fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                        fontSize: _fontSize,
                        fontWeight: _computeFontWeight(),
                        height: 2.0,
                        color: _isNightMode ? nightText : textDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick links: Tajweed Stop signs & Dua Khatm
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.menu_book_rounded,
                            size: 17,
                            color: _isNightMode ? nightBronze : bronzeAccent,
                          ),
                          label: Text(
                            'علامات الوقف',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isNightMode ? nightBronze : bronzeAccent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: (_isNightMode ? nightBronze : bronzeAccent).withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            MushafInfoSheets.showTajweedGuide(context, isDark: _isNightMode);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.auto_stories_rounded,
                            size: 17,
                            color: _isNightMode ? nightBronze : bronzeAccent,
                          ),
                          label: Text(
                            'دعاء الختم',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _isNightMode ? nightBronze : bronzeAccent,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: (_isNightMode ? nightBronze : bronzeAccent).withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            MushafInfoSheets.showDuaKhatm(context, isDark: _isNightMode);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    final currentPageData = repo.getPage(_currentPage);
    final pageSurahName = currentPageData?.surahName ?? widget.surah.name;
    final pageJuz = currentPageData?.juz ?? widget.surah.juz;
    final pageHizb = currentPageData?.hizb ?? 1;

    final bgColor = _isNightMode ? nightPaper : paperBg;
    final pageCardColor = _isNightMode ? nightPaper : paperBg;
    final bronze = _isNightMode ? nightBronze : bronzeAccent;

    final qState = context.watch<QuranBloc>().state;
    final isPageBookmarked = qState is QuranLoaded &&
        currentPageData != null &&
        currentPageData.segments.any(
          (seg) => seg.verses.any(
            (v) => qState.bookmarks.contains('${seg.surahId}:${v.id}'),
          ),
        );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: (_showControls || _isSelectionMode)
          ? AppBar(
              backgroundColor: pageCardColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 46,
              centerTitle: true,
              shape: Border(
                bottom: BorderSide(
                  color: paperBorder.withValues(alpha: _isNightMode ? 0.25 : 0.45),
                  width: 0.6,
                ),
              ),
              leading: _isSelectionMode
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'إلغاء التحديد',
                      onPressed: _clearSelection,
                    )
                  : IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: bronze, size: 18),
                      tooltip: 'رجوع',
                      onPressed: () => Navigator.pop(context),
                    ),
              title: _isSelectionMode
                  ? Text(
                      'تم تحديد ${toArabicDigits(_selectedAyat.length)} آيات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: bronze,
                      ),
                    )
                  : InkWell(
                      onTap: _showSurahPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'سورة $pageSurahName',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: bronze,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• الجزء ${toArabicDigits(pageJuz)}',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: bronze.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.keyboard_arrow_down_rounded, color: bronze, size: 16),
                          ],
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
                      // Jump to page dialog
                      IconButton(
                        icon: Icon(Icons.grid_view_rounded, color: bronze, size: 19),
                        tooltip: 'الانتقال إلى صفحة',
                        onPressed: _showJumpToPageDialog,
                      ),
                      // Display options (Night mode, font size)
                      IconButton(
                        icon: Icon(Icons.tune_rounded, color: bronze, size: 19),
                        tooltip: 'خيارات العرض',
                        onPressed: _showReaderOptionsMenu,
                      ),
                      // Bookmark current page
                      IconButton(
                        icon: Icon(
                          isPageBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isPageBookmarked ? AppColors.accentGold : bronze,
                          size: 20,
                        ),
                        tooltip: 'علامة الصفحة',
                        onPressed: () {
                          if (currentPageData != null && currentPageData.segments.isNotEmpty) {
                            final seg = currentPageData.segments.first;
                            final v = seg.verses.first;
                            context.read<QuranBloc>().add(
                                  ToggleBookmarkEvent(seg.surahId, v.id),
                                );
                            AppSnackBar.showSuccess(
                              context,
                              isPageBookmarked ? 'تمت إزالة علامة الصفحة' : 'تم حفظ الصفحة كعلامة مرجعية',
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
            )
          : null,

      body: PageView.builder(
        controller: _pageController,
        itemCount: 604,
        onPageChanged: (pageIndex) {
          setState(() {
            _currentPage = pageIndex + 1;
            _highlightedAyahId = null;
          });
          _recordCurrentPageAsLastRead();
        },
        itemBuilder: (context, index) {
          final pageNum = index + 1;
          final pageData = repo.getPage(pageNum);

          if (pageData == null) {
            return const Center(
              child: CircularProgressIndicator(color: goldAccent),
            );
          }

          return _buildMushafPage(pageData, pageNum);
        },
      ),

      // Bottom Bar or Floating Multi-Ayah Selection Bar
      bottomNavigationBar: _isSelectionMode
          ? _buildSelectionActionBar(pageCardColor, bronze)
          : (_showControls
              ? _buildBottomProgressControl(pageHizb, pageJuz, bronze, pageCardColor)
              : null),
    );
  }

  /// Minimal, elegant bottom progress control with a thin progress line and subtle metadata.
  Widget _buildBottomProgressControl(int pageHizb, int pageJuz, Color bronze, Color pageCardColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: pageCardColor,
        border: Border(
          top: BorderSide(
            color: paperBorder.withValues(alpha: _isNightMode ? 0.25 : 0.45),
            width: 0.6,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 38,
          child: Row(
            children: [
              // Page info click target
              InkWell(
                onTap: _showJumpToPageDialog,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'صفحة ${toArabicDigits(_currentPage)}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: bronze,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Thin reading progress bar with subtle metadata
              Expanded(
                child: GestureDetector(
                  onTap: _showJumpToPageDialog,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الجزء ${toArabicDigits(pageJuz)} • الحزب ${toArabicDigits(pageHizb)}',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: bronze.withValues(alpha: 0.75),
                            ),
                          ),
                          Text(
                            '٦٠٤',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 10,
                              color: bronze.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SizedBox(
                          height: 2.5,
                          child: LinearProgressIndicator(
                            value: _currentPage / 604.0,
                            backgroundColor: _isNightMode
                                ? Colors.white.withValues(alpha: 0.08)
                                : paperBorder.withValues(alpha: 0.6),
                            color: _isNightMode ? nightBronze : goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Minimal jump icon
              IconButton(
                icon: Icon(Icons.unfold_more_rounded, size: 18, color: bronze.withValues(alpha: 0.75)),
                tooltip: 'الانتقال السريع',
                onPressed: _showJumpToPageDialog,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),
      ),
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
      // Slightly dim non-highlighted text so the selected Ayah stands out clearly
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
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
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
    final bgCard = _isNightMode ? nightPaper : paperBg;

    // ── Seamless Fixed Mushaf Reading Surface ────────────────────────────────
    // The entire reading area is one continuous Mushaf paper surface.
    // No outer card container, no heavy borders, no floating shadows.
    // Proportional scaling via FittedBox guarantees ZERO vertical scrolling
    // and ZERO RenderFlex overflow on any device or viewport.
    // ──────────────────────────────────────────────────────────────────────────

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // ── Primary Mushaf Reading Surface ─────────────────────────────
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_isSelectionMode) {
                    setState(() => _showControls = !_showControls);
                  }
                },
                child: Container(
                  color: bgCard,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 380.0,
                          maxWidth: 380.0,
                          minHeight: 610.0,
                        ),
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

            // ── Page edge tap zones (navigation) ───────────────────────────
            // Tap LEFT edge → previous page (RTL Mushaf: right-to-left)
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
      },
    );
  }

  /// Builds the actual content of the fixed Mushaf page canvas.
  /// This runs on a 380-wide logical canvas and is scaled proportionally by FittedBox.
  Widget _buildMushafPageContent({
    required MushafPageModel pageData,
    required int pageNum,
    required Color textColor,
    required bool isCenteredPage,
    required QuranState qState,
    required Color bronze,
  }) {
    final bgCard = _isNightMode ? nightPaper : paperBg;

    return Container(
      color: bgCard,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Upper content (Header + Golden line + Cartouche + Ayat) ──────
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
              const SizedBox(height: 4),
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

          // ── Page Footer ───────────────────────────────────────────────────
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



