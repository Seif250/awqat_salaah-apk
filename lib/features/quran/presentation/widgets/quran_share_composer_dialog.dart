import 'dart:io';
import 'dart:math' as math;
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
import 'ayah_rosette.dart';

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
  double _fontSize = 22.0;
  bool _isGeneratingImage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final repo = context.read<QuranRepository>();

    // Determine initial surah
    if (widget.surahId != null) {
      _surahId = widget.surahId!;
    } else if (widget.items != null && widget.items!.isNotEmpty) {
      _surahId = widget.items!.first.surahId;
    } else {
      _surahId = 1;
    }

    final surah = repo.getSurahById(_surahId);
    _surahName = widget.surahName ?? surah?.name ?? (widget.items?.isNotEmpty == true ? widget.items!.first.surahName : '');
    _totalVerses = surah?.totalVerses ?? (surah?.verses.length ?? (widget.items?.length ?? 7));

    // Determine initial range
    if (widget.initialStartAyah != null) {
      _startAyah = widget.initialStartAyah!.clamp(1, _totalVerses);
      _endAyah = (widget.initialEndAyah ?? widget.initialStartAyah!).clamp(_startAyah, _totalVerses);
    } else if (widget.items != null && widget.items!.isNotEmpty) {
      final ids = widget.items!.map((e) => e.ayah.id).toList()..sort();
      _startAyah = ids.first.clamp(1, _totalVerses);
      _endAyah = ids.last.clamp(_startAyah, _totalVerses);
    } else {
      _startAyah = 1;
      _endAyah = 1;
    }

    _loadSelectedVerses(surah);
  }

  void _loadSelectedVerses([SurahModel? surahModel]) {
    final surah = surahModel ?? context.read<QuranRepository>().getSurahById(_surahId);
    if (surah != null && surah.verses.isNotEmpty) {
      _selectedVerses = surah.verses
          .where((v) => v.id >= _startAyah && v.id <= _endAyah)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
    } else if (widget.items != null && widget.items!.isNotEmpty) {
      _selectedVerses = widget.items!
          .where((item) => item.ayah.id >= _startAyah && item.ayah.id <= _endAyah)
          .map((item) => item.ayah)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
    }
  }

  void _updateRange({int? start, int? end}) {
    setState(() {
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
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Generates continuous text flow for sharing as text.
  /// No repeated surah name or metadata between verses.
  /// All verses flow seamlessly in Uthmani text with single metadata footer.
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
      buffer.writeln('سورة $_surahName • الآيات ${toArabicDigits(_startAyah)}–${toArabicDigits(_endAyah)}');
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
      AppSnackBar.showSuccess(context, 'تم نسخ الآيات الكريمة بنص متواصل بنجاح');
    }
  }

  Future<void> _shareAsImage() async {
    if (_isGeneratingImage) return;

    setState(() => _isGeneratingImage = true);

    try {
      final boundary =
          _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('عنصر المعاينة غير متاح');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null || pngBytes.isEmpty) {
        throw Exception('فشل تحويل الصورة إلى بايتات');
      }

      final fileName = 'quran_${_surahId}_${_startAyah}_${_endAyah}_${DateTime.now().millisecondsSinceEpoch}.png';

      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pngBytes, flush: true);

        final xFile = XFile(file.path, mimeType: 'image/png', name: fileName);
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            subject: 'سورة $_surahName (${toArabicDigits(_startAyah)}–${toArabicDigits(_endAyah)})',
            text: _generateTextPayload(),
          ),
        );
      } else {
        final xFile = XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: fileName,
        );
        await SharePlus.instance.share(
          ShareParams(
            files: [xFile],
            text: _generateTextPayload(),
          ),
        );
      }
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
    final dialogBg = isDark ? const Color(0xFF1B201D) : const Color(0xFFFAF7EE);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1E1A17);
    final bronze = isDark ? const Color(0xFFD4AF37) : const Color(0xFF7A583A);

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

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: AppColors.accentGold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مشاركة الآيات الكريمة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textThemeColor,
                        ),
                      ),
                      Text(
                        'سورة $_surahName • ${_startAyah == _endAyah ? "من آية ${toArabicDigits(_startAyah)} إلى آية ${toArabicDigits(_endAyah)}" : "من آية ${toArabicDigits(_startAyah)} إلى آية ${toArabicDigits(_endAyah)} (${toArabicDigits(_selectedVerses.length)} آيات)"}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Interactive Ayah Range Selector ──────────────────────────────
          _buildRangeSelectorCard(isDark, bronze),

          // Tabs: [ صورة ] [ نص ]
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.05),
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

  /// Compact, intuitive range selector card with step controls & quick chips
  Widget _buildRangeSelectorCard(bool isDark, Color bronze) {
    final cardBg = isDark ? const Color(0xFF141815) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFDFD4C0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Start Ayah Stepper
              Expanded(
                child: _buildStepperItem(
                  label: 'من آية',
                  value: _startAyah,
                  onDecrease: _startAyah > 1 ? () => _updateRange(start: _startAyah - 1) : null,
                  onIncrease: _startAyah < _totalVerses ? () => _updateRange(start: _startAyah + 1) : null,
                  onTapValue: () => _pickAyahDialog(isStart: true),
                  bronze: bronze,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1.2,
                height: 36,
                color: borderColor,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              // End Ayah Stepper
              Expanded(
                child: _buildStepperItem(
                  label: 'إلى آية',
                  value: _endAyah,
                  onDecrease: _endAyah > _startAyah ? () => _updateRange(end: _endAyah - 1) : null,
                  onIncrease: _endAyah < _totalVerses ? () => _updateRange(end: _endAyah + 1) : null,
                  onTapValue: () => _pickAyahDialog(isStart: false),
                  bronze: bronze,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quick Range Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('آية واحدة', _startAyah == _endAyah, () {
                  _updateRange(end: _startAyah);
                }, isDark),
                const SizedBox(width: 6),
                _buildQuickChip('+3 آيات', _endAyah == math.min(_totalVerses, _startAyah + 2), () {
                  _updateRange(end: math.min(_totalVerses, _startAyah + 2));
                }, isDark),
                const SizedBox(width: 6),
                _buildQuickChip('+5 آيات', _endAyah == math.min(_totalVerses, _startAyah + 4), () {
                  _updateRange(end: math.min(_totalVerses, _startAyah + 4));
                }, isDark),
                const SizedBox(width: 6),
                _buildQuickChip('+10 آيات', _endAyah == math.min(_totalVerses, _startAyah + 9), () {
                  _updateRange(end: math.min(_totalVerses, _startAyah + 9));
                }, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperItem({
    required String label,
    required int value,
    required VoidCallback? onDecrease,
    required VoidCallback? onIncrease,
    required VoidCallback onTapValue,
    required Color bronze,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onDecrease,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 16,
                  color: onDecrease != null ? bronze : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onTapValue,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  toArabicDigits(value),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: bronze,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onIncrease,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: onIncrease != null ? bronze : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? const Color(0xFF1E1A17)
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
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
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            child: const Text('تأكيد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageComposerTab(bool isDark) {
    return Column(
      children: [
        // Controls Row: Themes & Font Size
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildThemeButton(QuranShareTheme.medina, 'المدينة', const Color(0xFFFAF7EE)),
              const SizedBox(width: 8),
              _buildThemeButton(QuranShareTheme.emerald, 'زمردي', const Color(0xFF0F2D1F)),
              const SizedBox(width: 8),
              _buildThemeButton(QuranShareTheme.amoled, 'أسود', const Color(0xFF121614)),
              const Spacer(),

              // Font Size Selector
              IconButton(
                icon: const Icon(Icons.text_decrease_rounded, size: 18),
                tooltip: 'تصغير الخط',
                onPressed: () {
                  if (_fontSize > 16.0) setState(() => _fontSize -= 2.0);
                },
              ),
              Text(
                toArabicDigits(_fontSize.toInt()),
                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.text_increase_rounded, size: 18),
                tooltip: 'تكبير الخط',
                onPressed: () {
                  if (_fontSize < 30.0) setState(() => _fontSize += 2.0);
                },
              ),
            ],
          ),
        ),

        // Live Scrollable Preview Container
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Center(
              child: RepaintBoundary(
                key: _previewKey,
                child: QuranShareRenderer(
                  surahName: _surahName,
                  startAyah: _startAyah,
                  endAyah: _endAyah,
                  verses: _selectedVerses,
                  theme: _theme,
                  fontSize: _fontSize,
                ),
              ),
            ),
          ),
        ),

        // Bottom Action Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141815) : Colors.white,
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
                  _isGeneratingImage ? 'جاري تجهيز الصورة...' : 'مشاركة الصورة بجودة فائقة',
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

  Widget _buildThemeButton(QuranShareTheme theme, String label, Color previewColor) {
    final isSelected = _theme == theme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _theme = theme),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: previewColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : Colors.grey.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme == QuranShareTheme.medina ? const Color(0xFF1E1A17) : Colors.white,
          ),
        ),
      ),
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
                  icon: const Icon(Icons.copy_rounded, color: AppColors.accentGold, size: 20),
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

/// Dedicated, standalone Quran Share Image Renderer.
///
/// Features:
/// - Independent layout (not tied to Mushaf reader widget or screen size)
/// - Top: Application Name + Surah Name (No "أعوذ بالله" by default)
/// - Body: Continuous Quran text flow with inline rosettes
/// - Footer: Single Surah/Ayah range specification
/// - Auto-expanding dynamic height
class QuranShareRenderer extends StatelessWidget {
  final String surahName;
  final int startAyah;
  final int endAyah;
  final List<AyahModel> verses;
  final QuranShareTheme theme;
  final double fontSize;
  final String appName;

  const QuranShareRenderer({
    super.key,
    required this.surahName,
    required this.startAyah,
    required this.endAyah,
    required this.verses,
    required this.theme,
    required this.fontSize,
    this.appName = 'تطبيق وِرد',
  });

  @override
  Widget build(BuildContext context) {
    Color cardBg;
    Color borderColor;
    Color textColor;
    Color bronze;

    switch (theme) {
      case QuranShareTheme.medina:
        cardBg = const Color(0xFFFAF7EE);
        borderColor = const Color(0xFFDFD4C0);
        textColor = const Color(0xFF1E1A17);
        bronze = const Color(0xFF7A583A);
        break;
      case QuranShareTheme.emerald:
        cardBg = const Color(0xFF0F2D1F);
        borderColor = const Color(0xFF1F4D36);
        textColor = const Color(0xFFF0EAD6);
        bronze = const Color(0xFFD4AF37);
        break;
      case QuranShareTheme.amoled:
        cardBg = const Color(0xFF121614);
        borderColor = const Color(0xFF2C352E);
        textColor = const Color(0xFFE6E1D5);
        bronze = const Color(0xFFE5C158);
        break;
    }

    return Container(
      width: 460,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── TOP HEADER: Application Name & Surah Name ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 28, height: 1, color: bronze.withValues(alpha: 0.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  appName,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: bronze.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(width: 28, height: 1, color: bronze.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
              decoration: BoxDecoration(
                color: bronze.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bronze.withValues(alpha: 0.35), width: 1),
              ),
              child: Text(
                'سُورَةُ $surahName',
                style: TextStyle(
                  fontFamily: 'UthmanicHafs',
                  fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bronze,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: bronze.withValues(alpha: 0.25), thickness: 0.8),
          const SizedBox(height: 14),

          // ── BODY: Continuous Quran Text Flow ───────────────────────────────
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                children: [
                  for (final ayah in verses) ...[
                    TextSpan(
                      text: '${ayah.text} ',
                      style: TextStyle(
                        fontFamily: 'UthmanicHafs',
                        fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        height: 2.15,
                        color: textColor,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: AyahRosette(
                        ayahNumber: ayah.id,
                        size: (fontSize * 1.1).clamp(20.0, 28.0),
                        borderColor: bronze,
                        fillColor: bronze.withValues(alpha: 0.15),
                        textColor: textColor,
                      ),
                    ),
                    const TextSpan(text: ' '),
                  ],
                ],
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: bronze.withValues(alpha: 0.30), thickness: 1),
          const SizedBox(height: 8),

          // ── FOOTER: Surah Name & Selected Ayah Range ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                startAyah == endAyah
                    ? 'سورة $surahName • الآية ${toArabicDigits(startAyah)}'
                    : 'سورة $surahName • الآيات ${toArabicDigits(startAyah)}–${toArabicDigits(endAyah)}',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: bronze,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.mosque_rounded, size: 14, color: bronze),
                  const SizedBox(width: 4),
                  Text(
                    'تطبيق وِرد',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: bronze.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
