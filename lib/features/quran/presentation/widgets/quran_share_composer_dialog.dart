import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/ayah_model.dart';
import '../../data/models/surah_model.dart';
import '../../data/repositories/quran_repository.dart';
import 'share/quran_share_renderer.dart';
import 'share/share_layout_calculator.dart';

export 'share/quran_share_layout_engine.dart';
export 'share/quran_share_renderer.dart';
export 'share/share_layout_calculator.dart';

enum QuranShareTheme {
  medina,
  emerald,
  amoled,
}

class QuranAyahShareItem {
  final int surahId;
  final String surahName;
  final AyahModel ayah;

  const QuranAyahShareItem({
    required this.surahId,
    required this.surahName,
    required this.ayah,
  });
}

class QuranShareComposerDialog extends StatefulWidget {
  final List<QuranAyahShareItem>? items;
  final int? surahId;
  final String? surahName;
  final int? initialStartAyah;
  final int? initialEndAyah;

  const QuranShareComposerDialog({
    super.key,
    this.items,
    this.surahId,
    this.surahName,
    this.initialStartAyah,
    this.initialEndAyah,
  });

  static Future<void> show(
    BuildContext context, {
    List<QuranAyahShareItem>? items,
    int? surahId,
    String? surahName,
    int? initialStartAyah,
    int? initialEndAyah,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuranShareComposerDialog(
        items: items,
        surahId: surahId,
        surahName: surahName,
        initialStartAyah: initialStartAyah,
        initialEndAyah: initialEndAyah,
      ),
    );
  }

  @override
  State<QuranShareComposerDialog> createState() => _QuranShareComposerDialogState();
}

class _QuranShareComposerDialogState extends State<QuranShareComposerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _previewKey = GlobalKey();

  late int _surahId;
  late String _surahName;
  late int _totalVerses;
  late int _startAyah;
  late int _endAyah;
  List<AyahModel> _selectedVerses = [];

  QuranShareTheme _theme = QuranShareTheme.medina;
  bool _isGeneratingImage = false;
  int _currentPreviewPageIndex = 0;
  late ShareLayoutResult _cachedLayoutResult;

  String? get _crossSurahLabel {
    if (widget.items != null && widget.items!.isNotEmpty) {
      final surahIds = widget.items!.map((e) => e.surahId).toSet();
      if (surahIds.length > 1) {
        final first = widget.items!.first;
        final last = widget.items!.last;
        return 'سورة ${first.surahName} (${toArabicDigits(first.ayah.id)}) – سورة ${last.surahName} (${toArabicDigits(last.ayah.id)})';
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    QuranRepository? repo;
    try {
      repo = context.read<QuranRepository>();
    } catch (_) {
      repo = null;
    }

    // Determine initial surah
    if (widget.surahId != null) {
      _surahId = widget.surahId!;
    } else if (widget.items != null && widget.items!.isNotEmpty) {
      _surahId = widget.items!.first.surahId;
    } else {
      _surahId = 1;
    }

    final surah = repo?.getSurahById(_surahId);
    _surahName = widget.surahName ??
        surah?.name ??
        (widget.items?.isNotEmpty == true ? widget.items!.first.surahName : '');
    _totalVerses = surah?.totalVerses ??
        (surah?.verses.length ?? (widget.items?.length ?? 7));

    // Determine initial range
    if (widget.initialStartAyah != null) {
      _startAyah = widget.initialStartAyah!.clamp(1, _totalVerses);
      _endAyah = (widget.initialEndAyah ?? widget.initialStartAyah!)
          .clamp(_startAyah, _totalVerses);
    } else if (widget.items != null && widget.items!.isNotEmpty) {
      final ids = widget.items!.map((e) => e.ayah.id).toList()..sort();
      _startAyah = ids.first.clamp(1, _totalVerses);
      _endAyah = ids.last.clamp(_startAyah, _totalVerses);
    } else {
      _startAyah = 1;
      _endAyah = 1;
    }

    _loadSelectedVerses(surah);
    _cachedLayoutResult = QuranShareLayoutEngine.calculate(
      surahName: _surahName,
      verses: _selectedVerses,
    );
  }

  void _loadSelectedVerses([SurahModel? surahModel]) {
    SurahModel? surah = surahModel;
    if (surah == null) {
      try {
        surah = context.read<QuranRepository>().getSurahById(_surahId);
      } catch (_) {
        surah = null;
      }
    }
    if (surah != null && surah.verses.isNotEmpty) {
      _selectedVerses = surah.verses
          .where((v) => v.id >= _startAyah && v.id <= _endAyah)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
    } else if (widget.items != null && widget.items!.isNotEmpty) {
      _selectedVerses = widget.items!
          .where((item) =>
              item.ayah.id >= _startAyah && item.ayah.id <= _endAyah)
          .map((item) => item.ayah)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
    }
  }

  void _updateRange({int? start, int? end}) {
    setState(() {
      _currentPreviewPageIndex = 0;
      if (start != null) {
        _startAyah = start.clamp(1, _totalVerses);
        if (_startAyah > _endAyah) {
          _endAyah = _startAyah;
        }
      }
      if (end != null) {
        _endAyah = end.clamp(_startAyah, _totalVerses);
      }
      _loadSelectedVerses();
      _cachedLayoutResult = QuranShareLayoutEngine.calculate(
        surahName: _surahName,
        verses: _selectedVerses,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Generates continuous text flow for sharing as text.
  String _generateTextPayload() {
    final buffer = StringBuffer();
    buffer.write('﴿ ');
    for (int i = 0; i < _selectedVerses.length; i++) {
      final v = _selectedVerses[i];
      buffer.write(v.text);
      buffer.write(' ');
      buffer.write(toArabicDigits(v.id));
      if (i < _selectedVerses.length - 1) {
        buffer.write(' ');
      }
    }
    buffer.writeln(' ﴾');
    buffer.writeln();

    if (_startAyah == _endAyah) {
      buffer.writeln('سورة $_surahName • الآية ${toArabicDigits(_startAyah)}');
    } else {
      buffer.writeln(
          'سورة $_surahName • الآيات ${toArabicDigits(_startAyah)}–${toArabicDigits(_endAyah)}');
    }
    buffer.writeln('تطبيق وِرد • صلاتك، قرآنك، ذكرك');
    return buffer.toString().trim();
  }

  Future<void> _shareAsText() async {
    final text = _generateTextPayload();
    final subject = _startAyah == _endAyah
        ? 'آية من القرآن الكريم: سورة $_surahName'
        : 'آيات عطرة من القرآن الكريم: سورة $_surahName (${toArabicDigits(_startAyah)}–${toArabicDigits(_endAyah)})';

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }

  Future<void> _copyText() async {
    final text = _generateTextPayload();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppSnackBar.showSuccess(
          context, 'تم نسخ الآيات الكريمة بنص متواصل بنجاح');
    }
  }

  Future<void> _shareAsImage() async {
    if (_isGeneratingImage) return;

    setState(() => _isGeneratingImage = true);

    try {
      final layoutResult = _cachedLayoutResult;
      final allFiles = <XFile>[];

      if (layoutResult.totalPages == 1) {
        final boundary = _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null) {
          throw Exception('عنصر المعاينة غير متاح');
        }

        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData?.buffer.asUint8List();

        if (pngBytes == null || pngBytes.isEmpty) {
          throw Exception('فشل تحويل الصورة إلى بايتات');
        }

        final fileName =
            'quran_${_surahId}_${_startAyah}_${_endAyah}_${DateTime.now().millisecondsSinceEpoch}.png';

        if (!kIsWeb) {
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/$fileName');
          await file.writeAsBytes(pngBytes, flush: true);
          allFiles.add(XFile(file.path, mimeType: 'image/png', name: fileName));
        } else {
          allFiles.add(
              XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName));
        }
      } else {
        final originalPageIndex = _currentPreviewPageIndex;
        for (int i = 0; i < layoutResult.totalPages; i++) {
          setState(() => _currentPreviewPageIndex = i);
          await WidgetsBinding.instance.endOfFrame;
          await Future.delayed(const Duration(milliseconds: 60));

          final boundary = _previewKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
          if (boundary != null) {
            final image = await boundary.toImage(pixelRatio: 1.0);
            final byteData =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final pngBytes = byteData?.buffer.asUint8List();
            if (pngBytes != null && pngBytes.isNotEmpty) {
              final fileName =
                  'quran_${_surahId}_page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png';
              if (!kIsWeb) {
                final tempDir = await getTemporaryDirectory();
                final file = File('${tempDir.path}/$fileName');
                await file.writeAsBytes(pngBytes, flush: true);
                allFiles.add(
                    XFile(file.path, mimeType: 'image/png', name: fileName));
              } else {
                allFiles.add(XFile.fromData(pngBytes,
                    mimeType: 'image/png', name: fileName));
              }
            }
          }
        }

        if (mounted) {
          setState(() => _currentPreviewPageIndex = originalPageIndex);
        }
      }

      if (allFiles.isEmpty) {
        throw Exception('فشل إنشاء صور المشاركة');
      }

      await SharePlus.instance.share(
        ShareParams(
          files: allFiles,
          subject:
              'سورة $_surahName (${toArabicDigits(_startAyah)}–${toArabicDigits(_endAyah)})',
          text: null,
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'فشل إنشاء ومشاركة الصورة: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1B201D) : const Color(0xFFF6F0E4);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1E1A17);
    final bronze = isDark ? const Color(0xFFD4AF37) : const Color(0xFF7A583A);
    final cardBg = isDark ? const Color(0xFF141815) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFDFD4C0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Minimal Header with Theme Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'إغلاق',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'مشاركة الآيات الكريمة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textThemeColor,
                        ),
                      ),
                      Text(
                        _crossSurahLabel != null
                            ? 'سورة $_surahName • (${_startAyah == _endAyah ? "الآية ${toArabicDigits(_startAyah)}" : "الآيات ${toArabicDigits(_startAyah)} إلى ${toArabicDigits(_endAyah)}"}) ($_crossSurahLabel)'
                            : 'سورة $_surahName • ${_startAyah == _endAyah ? "الآية ${toArabicDigits(_startAyah)}" : "الآيات ${toArabicDigits(_startAyah)} إلى ${toArabicDigits(_endAyah)}"}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildThemeSelectorButton(isDark),
              ],
            ),
          ),

          // Hero Ayah Range Selector (Large, Prominent, Islamic Styling)
          _buildHeroRangeSelector(isDark, bronze, cardBg, borderColor),

          // Tabs: [ صورة ] [ نص ]
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black26
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: const Color(0xFF1E1A17),
              unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(
                  icon: Icon(Icons.image_outlined, size: 18),
                  text: 'مشاركة كصورة',
                ),
                Tab(
                  icon: Icon(Icons.text_fields_rounded, size: 18),
                  text: 'مشاركة كنص',
                ),
              ],
            ),
          ),

          // Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildImageComposerTab(isDark),
                _buildTextComposerTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Compact, elegant Theme Selector button in top bar
  Widget _buildThemeSelectorButton(bool isDark) {
    Color activeColor;
    switch (_theme) {
      case QuranShareTheme.medina:
        activeColor = const Color(0xFFF6F0E4);
        break;
      case QuranShareTheme.emerald:
        activeColor = const Color(0xFF0F2D1F);
        break;
      case QuranShareTheme.amoled:
        activeColor = const Color(0xFF101412);
        break;
    }

    return PopupMenuButton<QuranShareTheme>(
      tooltip: 'مظهر المشاركة',
      initialValue: _theme,
      onSelected: (theme) => setState(() => _theme = theme),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF1E2420) : const Color(0xFFFDFBF7),
      itemBuilder: (ctx) => [
        _buildThemePopupItem(
            QuranShareTheme.medina, 'المدينة', const Color(0xFFF6F0E4), isDark),
        _buildThemePopupItem(
            QuranShareTheme.emerald, 'زمردي', const Color(0xFF0F2D1F), isDark),
        _buildThemePopupItem(
            QuranShareTheme.amoled, 'أسود', const Color(0xFF101412), isDark),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accentGold, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.palette_outlined,
              size: 16,
              color: AppColors.accentGold,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<QuranShareTheme> _buildThemePopupItem(
    QuranShareTheme theme,
    String label,
    Color color,
    bool isDark,
  ) {
    final isSelected = _theme == theme;
    return PopupMenuItem<QuranShareTheme>(
      value: theme,
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.accentGold : Colors.grey,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppColors.accentGold
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded,
                size: 18, color: AppColors.accentGold),
          ],
        ],
      ),
    );
  }

  /// Large, dignified Hero Range Selector
  Widget _buildHeroRangeSelector(
      bool isDark, Color bronze, Color cardBg, Color borderColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Start Ayah (من آية)
          Expanded(
            child: _buildAyahRangeSection(
              label: 'مِنْ آيَة',
              value: _startAyah,
              onDecrease: _startAyah > 1
                  ? () => _updateRange(start: _startAyah - 1)
                  : null,
              onIncrease: _startAyah < _totalVerses
                  ? () => _updateRange(start: _startAyah + 1)
                  : null,
              onTapValue: () => _pickAyahDialog(isStart: true),
              bronze: bronze,
              isDark: isDark,
            ),
          ),

          // Central Decorative Divider with Ayah Count Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accentGold.withValues(alpha: 0.3)),
            ),
            child: Text(
              _selectedVerses.length == 1
                  ? 'آية واحدة'
                  : '${toArabicDigits(_selectedVerses.length)} آيات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: bronze,
              ),
            ),
          ),

          // End Ayah (إِلَى آيَة)
          Expanded(
            child: _buildAyahRangeSection(
              label: 'إِلَى آيَة',
              value: _endAyah,
              onDecrease: _endAyah > _startAyah
                  ? () => _updateRange(end: _endAyah - 1)
                  : null,
              onIncrease: _endAyah < _totalVerses
                  ? () => _updateRange(end: _endAyah + 1)
                  : null,
              onTapValue: () => _pickAyahDialog(isStart: false),
              bronze: bronze,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahRangeSection({
    required String label,
    required int value,
    required VoidCallback? onDecrease,
    required VoidCallback? onIncrease,
    required VoidCallback onTapValue,
    required Color bronze,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minus Button
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onDecrease,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: onDecrease != null
                        ? bronze
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Number Button (Large Arabic numeral)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onTapValue,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 38),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.accentGold.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      toArabicDigits(value),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: bronze,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Plus Button
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onIncrease,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: onIncrease != null
                        ? bronze
                        : Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickAyahDialog({required bool isStart}) {
    final controller = TextEditingController(
      text: (isStart ? _startAyah : _endAyah).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isStart ? 'اختر بداية النطاق' : 'اختر نهاية النطاق',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أدخل رقم الآية (١ إلى ${toArabicDigits(_totalVerses)})',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              backgroundColor: AppColors.accentGold,
              foregroundColor: const Color(0xFF1E1A17),
            ),
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null) {
                if (isStart) {
                  _updateRange(start: val);
                } else {
                  _updateRange(end: val);
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('تأكيد',
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageComposerTab(bool isDark) {
    final layoutResult = _cachedLayoutResult;
    final clampedPageIndex =
        _currentPreviewPageIndex.clamp(0, layoutResult.totalPages - 1);
    final currentPageData = layoutResult.pages[clampedPageIndex];

    return Column(
      children: [
        // Multi-page Pagination Selector (ONLY if content spans multiple pages)
        if (layoutResult.totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15),
                  onPressed: clampedPageIndex > 0
                      ? () => setState(() =>
                          _currentPreviewPageIndex = clampedPageIndex - 1)
                      : null,
                  tooltip: 'الصفحة السابقة',
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  child: Text(
                    'صفحة ${toArabicDigits(clampedPageIndex + 1)} من ${toArabicDigits(layoutResult.totalPages)}',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 15),
                  onPressed: clampedPageIndex < layoutResult.totalPages - 1
                      ? () => setState(() =>
                          _currentPreviewPageIndex = clampedPageIndex + 1)
                      : null,
                  tooltip: 'الصفحة التالية',
                ),
              ],
            ),
          ),

        // Live Preview Container (Maximized to occupy available viewport)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: currentPageData.canvasWidth,
                  height: currentPageData.canvasHeight,
                  child: RepaintBoundary(
                    key: _previewKey,
                    child: QuranShareRenderer(
                      pageData: currentPageData,
                      theme: _theme,
                      crossSurahLabel: _crossSurahLabel,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom Action Button: «مشاركة الصورة بجودة عالية»
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141815) : const Color(0xFFF6F0E4),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: const Color(0xFF1E1A17),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isGeneratingImage ? null : _shareAsImage,
                icon: _isGeneratingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1E1A17),
                        ),
                      )
                    : const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  _isGeneratingImage
                      ? 'جاري تجهيز الصورة...'
                      : (layoutResult.totalPages > 1
                          ? 'مشاركة الصور (${toArabicDigits(layoutResult.totalPages)})'
                          : 'مشاركة الصورة'),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextComposerTab(bool isDark) {
    final text = _generateTextPayload();
    final cardBg = isDark ? const Color(0xFF141815) : Colors.white;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                    fontSize: 19,
                    height: 2.1,
                    color: isDark ? Colors.white : const Color(0xFF1E1A17),
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.accentGold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _copyText,
                  icon: const Icon(Icons.copy_rounded,
                      color: AppColors.accentGold, size: 20),
                  label: const Text(
                    'نسخ النص',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: const Color(0xFF1E1A17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _shareAsText,
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: const Text(
                    'مشاركة نصية',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
