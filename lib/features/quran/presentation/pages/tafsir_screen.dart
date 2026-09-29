import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/tafsir_model.dart';
import '../../data/repositories/quran_repository.dart';
import '../../data/repositories/tafsir_repository.dart';

/// Dedicated, comfortable reading surface for Ayah Tafsir.
class TafsirScreen extends StatefulWidget {
  final String verseKey; // "surahId:ayahId" e.g. "2:255"
  final String surahName;
  final int ayahNumber;
  final String ayahText;
  final int? initialResourceId;

  const TafsirScreen({
    super.key,
    required this.verseKey,
    required this.surahName,
    required this.ayahNumber,
    required this.ayahText,
    this.initialResourceId,
  });

  static Future<void> push(
    BuildContext context, {
    required String verseKey,
    required String surahName,
    required int ayahNumber,
    required String ayahText,
    int? initialResourceId,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TafsirScreen(
          verseKey: verseKey,
          surahName: surahName,
          ayahNumber: ayahNumber,
          ayahText: ayahText,
          initialResourceId: initialResourceId,
        ),
      ),
    );
  }

  @override
  State<TafsirScreen> createState() => _TafsirScreenState();
}

class _TafsirScreenState extends State<TafsirScreen> {
  late int _selectedResourceId;
  List<TafsirResource> _availableResources = [];
  Tafsir? _tafsir;
  bool _isLoading = true;
  String? _errorMessage;
  double _tafsirFontSize = 17.5;

  @override
  void initState() {
    super.initState();
    final quranRepo = context.read<QuranRepository>();
    _selectedResourceId = widget.initialResourceId ?? quranRepo.defaultTafsirResourceId;

    _loadResourcesAndTafsir();
  }

  Future<void> _loadResourcesAndTafsir() async {
    final repo = context.read<TafsirRepository>();

    // 1. Load resources list
    try {
      final resources = await repo.getAvailableTafsirs();
      if (mounted) {
        setState(() {
          _availableResources = resources;
          if (!_availableResources.any((r) => r.id == _selectedResourceId)) {
            if (_availableResources.isNotEmpty) {
              _selectedResourceId = _availableResources.first.id;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _availableResources = TafsirRepositoryImpl.defaultArabicTafsirs;
        });
      }
    }

    // 2. Fetch Tafsir for selected Ayah
    _fetchTafsirContent();
  }

  Future<void> _fetchTafsirContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = context.read<TafsirRepository>();

    try {
      final result = await repo.getTafsirForAyah(
        verseKey: widget.verseKey,
        tafsirResourceId: _selectedResourceId,
      );

      if (mounted) {
        setState(() {
          _tafsir = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'تعذر تحميل التفسير. يرجى التحقق من الاتصال بالإنترنت والمحاولة مجدداً.';
        });
      }
    }
  }

  void _onSelectResource(TafsirResource resource) {
    if (_selectedResourceId == resource.id) return;
    setState(() {
      _selectedResourceId = resource.id;
    });
    // Persist as current preferred default
    context.read<QuranRepository>().setDefaultTafsirResourceId(resource.id);
    _fetchTafsirContent();
  }

  void _showResourcePickerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.60,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B201D) : const Color(0xFFFAF6EE),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'اختر كتاب التفسير',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _availableResources.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: (isDark ? Colors.white12 : Colors.black12),
                  ),
                  itemBuilder: (ctx, index) {
                    final res = _availableResources[index];
                    final isSelected = res.id == _selectedResourceId;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? AppColors.accentGold
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                      title: Text(
                        res.name,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? AppColors.accentGold
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      subtitle: res.authorName.isNotEmpty
                          ? Text(
                              res.authorName,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _onSelectResource(res);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgScaffold = isDark ? const Color(0xFF121714) : const Color(0xFFF6F0E4);
    final cardBg = isDark ? const Color(0xFF1B221E) : const Color(0xFFFFFDF8);
    final textColor = isDark ? const Color(0xFFECE8DF) : const Color(0xFF302923);
    final goldColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFFB58A4A);

    final selectedResource = _availableResources.firstWhere(
      (r) => r.id == _selectedResourceId,
      orElse: () => TafsirResource(
        id: _selectedResourceId,
        name: _tafsir?.resourceName ?? 'التفسير الميسر',
        authorName: '',
        language: 'arabic',
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgScaffold,
        appBar: AppBar(
          backgroundColor: bgScaffold,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
            tooltip: 'رجوع',
          ),
          centerTitle: true,
          title: Text(
            'تفسير الآية',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          actions: [
            // Font size controls
            IconButton(
              icon: const Icon(Icons.text_decrease_rounded, size: 20),
              tooltip: 'تصغير خط التفسير',
              onPressed: () {
                if (_tafsirFontSize > 14.0) {
                  setState(() => _tafsirFontSize -= 1.5);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.text_increase_rounded, size: 20),
              tooltip: 'تكبير خط التفسير',
              onPressed: () {
                if (_tafsirFontSize < 28.0) {
                  setState(() => _tafsirFontSize += 1.5);
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. Ayah Context Header ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سُورَةُ ${widget.surahName}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: goldColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: goldColor.withValues(alpha: 0.35),
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      'الآية ${toArabicDigits(widget.ayahNumber)}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: goldColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── 2. Quran Ayah Text (Separated visually) ──────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: goldColor.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '﴿ ${widget.ayahText} ﴾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 2.0,
                    color: textColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 3. Subtle Ornamental Divider ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: goldColor.withValues(alpha: 0.25),
                      thickness: 0.8,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.circle, size: 5, color: goldColor),
                  ),
                  Expanded(
                    child: Divider(
                      color: goldColor.withValues(alpha: 0.25),
                      thickness: 0.8,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── 4. Tafsir Source Selector Bar ────────────────────────────────
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _showResourcePickerDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: goldColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مصدر التفسير',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              selectedResource.name,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: goldColor,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. Tafsir Body Content ───────────────────────────────────────
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: goldColor,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'جارٍ جلب التفسير...',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          size: 42,
                          color: Colors.grey.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor: const Color(0xFF1E1A17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _fetchTafsirContent,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_tafsir != null && _tafsir!.text.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                      width: 1.0,
                    ),
                  ),
                  child: SelectableText(
                    _tafsir!.text,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: _tafsirFontSize,
                      fontWeight: FontWeight.w500,
                      height: 1.85,
                      color: textColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'لا يتوفر نص تفسير لهذه الآية في المصدر المحدد.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
