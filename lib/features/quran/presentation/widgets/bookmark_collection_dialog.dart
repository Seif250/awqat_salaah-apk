import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../data/models/bookmark_collection_model.dart';
import '../../data/models/bookmark_model.dart';
import '../bloc/quran_bloc.dart';
import '../bloc/quran_event.dart';
import '../bloc/quran_state.dart';

class BookmarkCollectionDialog extends StatefulWidget {
  final List<({int surahId, int ayahId, int page})> ayat;
  final String surahName;

  const BookmarkCollectionDialog({
    super.key,
    required this.ayat,
    required this.surahName,
  });

  static Future<void> show(
    BuildContext context, {
    required List<({int surahId, int ayahId, int page})> ayat,
    required String surahName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookmarkCollectionDialog(ayat: ayat, surahName: surahName),
    );
  }

  @override
  State<BookmarkCollectionDialog> createState() => _BookmarkCollectionDialogState();
}

class _BookmarkCollectionDialogState extends State<BookmarkCollectionDialog> {
  final TextEditingController _noteController = TextEditingController();
  String _selectedColor = '#2E7D32';
  final Set<String> _selectedCollectionIds = {};

  final List<({String hex, String name, Color color})> _palette = const [
    (hex: '#D4AF37', name: 'ذهبي أصيل', color: Color(0xFFD4AF37)),
    (hex: '#2E7D32', name: 'زمردي', color: Color(0xFF2E7D32)),
    (hex: '#1976D2', name: 'ياقوت أزرق', color: Color(0xFF1976D2)),
    (hex: '#C2185B', name: 'عقيقي وردي', color: Color(0xFFC2185B)),
    (hex: '#7B1FA2', name: 'أرجواني', color: Color(0xFF7B1FA2)),
    (hex: '#7A583A', name: 'برونزي أندلسي', color: Color(0xFF7A583A)),
  ];

  @override
  void initState() {
    super.initState();
    // If single ayah and already bookmarked, pre-fill color, note and collections
    if (widget.ayat.length == 1) {
      final qState = context.read<QuranBloc>().state;
      if (qState is QuranLoaded) {
        final existing = qState.richBookmarks.firstWhere(
          (b) =>
              b.surahId == widget.ayat.first.surahId &&
              b.ayahNumber == widget.ayat.first.ayahId,
          orElse: () => BookmarkModel(
            id: '',
            ayahId: 0,
            surahId: 0,
            ayahNumber: 0,
            pageNumber: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        if (existing.id.isNotEmpty) {
          _selectedColor = existing.color;
          if (existing.note != null) _noteController.text = existing.note!;
          _selectedCollectionIds.addAll(existing.collectionIds);
        }
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showCreateCollectionDialog() {
    final nameController = TextEditingController();
    String collectionColor = '#D4AF37';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'إنشاء مجموعة علامات جديدة',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'مثال: آيات الشفاء، تدبر المساء...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'اختر لون المجموعة:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _palette.map((p) {
                  final isSel = collectionColor == p.hex;
                  return GestureDetector(
                    onTap: () => setDialogState(() => collectionColor = p.hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: p.color.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSel
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
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
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final newCol = BookmarkCollectionModel(
                    id: 'col_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    color: collectionColor,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  context.read<QuranBloc>().add(SaveBookmarkCollectionEvent(newCol));
                  setState(() {
                    _selectedCollectionIds.add(newCol.id);
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text(
                'إنشاء',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveBookmarks() {
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    if (widget.ayat.length == 1) {
      final single = widget.ayat.first;
      final model = BookmarkModel(
        id: '${single.surahId}:${single.ayahId}',
        ayahId: single.ayahId,
        surahId: single.surahId,
        ayahNumber: single.ayahId,
        pageNumber: single.page,
        color: _selectedColor,
        note: note,
        collectionIds: _selectedCollectionIds.toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      context.read<QuranBloc>().add(SaveRichBookmarkEvent(model));
      AppSnackBar.showSuccess(
        context,
        'تم حفظ الآية في العلامات والمجموعات بنجاح',
      );
    } else {
      // Multiple Ayat
      context.read<QuranBloc>().add(
            BookmarkMultipleAyatEvent(
              widget.ayat,
              collectionId: _selectedCollectionIds.isNotEmpty
                  ? _selectedCollectionIds.first
                  : null,
              color: _selectedColor,
            ),
          );
      AppSnackBar.showSuccess(
        context,
        'تمت إضافة ${toArabicDigits(widget.ayat.length)} آيات إلى العلامات بنجاح',
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1B201D) : const Color(0xFFFAF7EE);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF1E1A17);

    return BlocBuilder<QuranBloc, QuranState>(
      builder: (context, state) {
        final collections =
            state is QuranLoaded ? state.collections : <BookmarkCollectionModel>[];

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bookmark_add_rounded,
                          color: AppColors.accentGold,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.ayat.length == 1
                                  ? 'حفظ الآية في العلامات والمجموعات'
                                  : 'حفظ ${toArabicDigits(widget.ayat.length)} آيات في مجموعة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textThemeColor,
                              ),
                            ),
                            Text(
                              widget.ayat.length == 1
                                  ? 'سورة ${widget.surahName} • الآية ${toArabicDigits(widget.ayat.first.ayahId)}'
                                  : 'تصنيف الآيات المختارة لسهولة الرجوع والتدبر',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
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
                  const SizedBox(height: 18),

                  // Color selection
                  Text(
                    'لون العلامة المرجعية:',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textThemeColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: _palette.map((p) {
                      final isSel = _selectedColor == p.hex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = p.hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: p.color.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: isSel
                              ? const Icon(Icons.check, size: 20, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Collections Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'إضافة إلى مجموعة:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textThemeColor,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.accentGold,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: _showCreateCollectionDialog,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'مجموعة جديدة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Uncategorized chip
                      FilterChip(
                        selected: _selectedCollectionIds.isEmpty,
                        label: const Text('بدون مجموعة'),
                        labelStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _selectedCollectionIds.isEmpty
                              ? const Color(0xFF1E1A17)
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        backgroundColor:
                            isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        selectedColor: AppColors.accentGold,
                        checkmarkColor: const Color(0xFF1E1A17),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCollectionIds.clear());
                        },
                      ),

                      // User and Default Collections
                      for (final col in collections) ...[
                        FilterChip(
                          selected: _selectedCollectionIds.contains(col.id),
                          avatar: CircleAvatar(
                            backgroundColor: Color(
                              int.parse(col.color.replaceFirst('#', '0xFF')),
                            ),
                            radius: 6,
                          ),
                          label: Text(col.name),
                          labelStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedCollectionIds.contains(col.id)
                                ? const Color(0xFF1E1A17)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          backgroundColor:
                              isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          selectedColor: AppColors.accentGold,
                          checkmarkColor: const Color(0xFF1E1A17),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedCollectionIds.add(col.id);
                              } else {
                                _selectedCollectionIds.remove(col.id);
                              }
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Optional Note (especially useful for single Ayah)
                  if (widget.ayat.length == 1) ...[
                    Text(
                      'ملاحظة أو تدبر خاص (اختياري):',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textThemeColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'اكتب فائدة، خاطرة، أو سبب حفظ الآية...',
                        hintStyle: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Save Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: const Color(0xFF1E1A17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _saveBookmarks,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text(
                        widget.ayat.length == 1
                            ? 'تأكيد وحفظ العلامة'
                            : 'حفظ ${toArabicDigits(widget.ayat.length)} آيات في العلامات',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
