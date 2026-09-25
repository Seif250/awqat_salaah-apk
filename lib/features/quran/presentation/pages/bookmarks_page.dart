import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../data/models/bookmark_collection_model.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/surah_model.dart';
import '../bloc/quran_bloc.dart';
import '../bloc/quran_event.dart';
import '../bloc/quran_state.dart';
import '../widgets/bookmark_collection_dialog.dart';
import '../widgets/quran_share_composer_dialog.dart';
import 'surah_detail_page.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterCollectionId;

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAyah(BookmarkModel bk, List<SurahModel> allSurahs) {
    final surah = allSurahs.firstWhere(
      (s) => s.id == bk.surahId,
      orElse: () => allSurahs.first,
    );
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: SurahDetailPage(
          surah: surah,
          initialAyah: bk.ayahNumber,
        ),
      ),
    );
  }

  void _showColorPicker(BookmarkModel bk) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تغيير لون العلامة المرجعية',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: _palette.map((p) {
                final isSel = bk.color == p.hex;
                return GestureDetector(
                  onTap: () {
                    context.read<QuranBloc>().add(
                          UpdateBookmarkColorEvent(bk.surahId, bk.ayahNumber, p.hex),
                        );
                    Navigator.pop(ctx);
                    AppSnackBar.showSuccess(context, 'تم تحديث لون العلامة');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSel ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: p.color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: isSel ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(BookmarkModel bk) {
    final noteController = TextEditingController(text: bk.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تدبر أو ملاحظة على الآية',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'اكتب فائدة أو تدبراً...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
              final note = noteController.text.trim().isEmpty ? null : noteController.text.trim();
              context.read<QuranBloc>().add(
                    UpdateBookmarkNoteEvent(bk.surahId, bk.ayahNumber, note),
                  );
              Navigator.pop(ctx);
              AppSnackBar.showSuccess(context, 'تم حفظ الملاحظة بنجاح');
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _shareBookmark(BookmarkModel bk, SurahModel surah) {
    final ayah = surah.verses.firstWhere(
      (v) => v.id == bk.ayahNumber,
      orElse: () => surah.verses.first,
    );
    QuranShareComposerDialog.show(
      context,
      items: [
        QuranAyahShareItem(
          surahId: surah.id,
          surahName: surah.name,
          ayah: ayah,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<QuranBloc, QuranState>(
      builder: (context, state) {
        if (state is! QuranLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.accentGold)),
          );
        }

        final richBookmarks = state.richBookmarks;
        final collections = state.collections;
        final allSurahs = state.allSurahs;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            title: const Text(
              'العلامات المرجعية والمجموعات',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.accentGold,
              labelColor: isDark ? AppColors.accentGoldLight : AppColors.primary,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'جميع العلامات (${toArabicDigits(richBookmarks.length)})'),
                Tab(text: 'المجموعات (${toArabicDigits(collections.length)})'),
                const Tab(text: 'أحدث الإضافات'),
                const Tab(text: 'بحث في العلامات'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: All Bookmarks
              _buildBookmarksList(
                bookmarks: richBookmarks,
                collections: collections,
                allSurahs: allSurahs,
                isDark: isDark,
              ),

              // Tab 2: Collections View
              _buildCollectionsView(
                collections: collections,
                bookmarks: richBookmarks,
                allSurahs: allSurahs,
                isDark: isDark,
              ),

              // Tab 3: Recently Added
              _buildBookmarksList(
                bookmarks: List.from(richBookmarks)
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
                collections: collections,
                allSurahs: allSurahs,
                isDark: isDark,
              ),

              // Tab 4: Search Bookmarks
              _buildSearchTab(
                bookmarks: richBookmarks,
                collections: collections,
                allSurahs: allSurahs,
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookmarksList({
    required List<BookmarkModel> bookmarks,
    required List<BookmarkCollectionModel> collections,
    required List<SurahModel> allSurahs,
    required bool isDark,
  }) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.collections_bookmark_outlined,
                size: 64,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد علامات مرجعية محفوظة بعد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'يمكنك النقر على رمز الآية أو تحديد عدة آيات لحفظها وتصنيفها',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bk = bookmarks[index];
        final surah = allSurahs.firstWhere(
          (s) => s.id == bk.surahId,
          orElse: () => allSurahs.first,
        );
        final ayah = surah.verses.firstWhere(
          (v) => v.id == bk.ayahNumber,
          orElse: () => surah.verses.first,
        );

        return _buildBookmarkCard(
          bk: bk,
          surah: surah,
          ayahText: ayah.text,
          collections: collections,
          allSurahs: allSurahs,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildBookmarkCard({
    required BookmarkModel bk,
    required SurahModel surah,
    required String ayahText,
    required List<BookmarkCollectionModel> collections,
    required List<SurahModel> allSurahs,
    required bool isDark,
  }) {
    final bkColor = Color(int.parse(bk.color.replaceFirst('#', '0xFF')));
    final assignedCols = collections.where((c) => bk.collectionIds.contains(c.id)).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bkColor.withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openAyah(bk, allSurahs),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Surah Name + Ayah Number + Color Badge + Menu
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: bkColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'سورة ${surah.name}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• الآية ${toArabicDigits(bk.ayahNumber)}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: bkColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ص ${toArabicDigits(bk.pageNumber)}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Actions Popup Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: isDark ? Colors.white60 : Colors.black54,
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (val) {
                        switch (val) {
                          case 'open':
                            _openAyah(bk, allSurahs);
                            break;
                          case 'color':
                            _showColorPicker(bk);
                            break;
                          case 'note':
                            _showNoteDialog(bk);
                            break;
                          case 'collections':
                            BookmarkCollectionDialog.show(
                              context,
                              ayat: [(surahId: bk.surahId, ayahId: bk.ayahNumber, page: bk.pageNumber)],
                              surahName: surah.name,
                            );
                            break;
                          case 'share':
                            _shareBookmark(bk, surah);
                            break;
                          case 'delete':
                            context.read<QuranBloc>().add(
                                  DeleteRichBookmarkEvent(bk.surahId, bk.ayahNumber),
                                );
                            AppSnackBar.showSuccess(context, 'تمت إزالة العلامة');
                            break;
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.menu_book_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('الانتقال للآية', style: TextStyle(fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'color',
                          child: Row(
                            children: [
                              Icon(Icons.palette_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('تغيير اللون', style: TextStyle(fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'note',
                          child: Row(
                            children: [
                              Icon(Icons.edit_note_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('إضافة/تعديل تدبر', style: TextStyle(fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'collections',
                          child: Row(
                            children: [
                              Icon(Icons.folder_open_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('تعديل المجموعات', style: TextStyle(fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('مشاركة (صورة/نص)', style: TextStyle(fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('إزالة العلامة', style: TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quran Text Snippet
                Text(
                  ayahText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: const ['AmiriQuran', 'Cairo', 'serif'],
                    fontSize: 16,
                    height: 1.8,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E1A17),
                  ),
                  textDirection: TextDirection.rtl,
                ),

                // Optional Note snippet
                if (bk.note != null && bk.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: bkColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: bkColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note_alt_rounded, size: 14, color: bkColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            bk.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Collection Chips
                if (assignedCols.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: assignedCols.map((c) {
                      final cColor = Color(int.parse(c.color.replaceFirst('#', '0xFF')));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          c.name,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: cColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionsView({
    required List<BookmarkCollectionModel> collections,
    required List<BookmarkModel> bookmarks,
    required List<SurahModel> allSurahs,
    required bool isDark,
  }) {
    if (_filterCollectionId != null) {
      final selectedCol = collections.firstWhere(
        (c) => c.id == _filterCollectionId,
        orElse: () => BookmarkCollectionModel(
          id: '',
          name: '',
          color: '#D4AF37',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      final filteredBks =
          bookmarks.where((b) => b.collectionIds.contains(_filterCollectionId)).toList();

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => setState(() => _filterCollectionId = null),
                ),
                Text(
                  selectedCol.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${toArabicDigits(filteredBks.length)} آيات)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBookmarksList(
              bookmarks: filteredBks,
              collections: collections,
              allSurahs: allSurahs,
              isDark: isDark,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: collections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final col = collections[index];
        final colColor = Color(int.parse(col.color.replaceFirst('#', '0xFF')));
        final count = bookmarks.where((b) => b.collectionIds.contains(col.id)).length;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colColor.withValues(alpha: isDark ? 0.35 : 0.4),
              width: 1.2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colColor.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.folder_special_rounded, color: colColor, size: 24),
            ),
            title: Text(
              col.name,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            subtitle: Text(
              '${toArabicDigits(count)} آيات محفوظة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
            onTap: () {
              setState(() => _filterCollectionId = col.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchTab({
    required List<BookmarkModel> bookmarks,
    required List<BookmarkCollectionModel> collections,
    required List<SurahModel> allSurahs,
    required bool isDark,
  }) {
    final query = _searchQuery.trim().toLowerCase();
    final results = bookmarks.where((b) {
      if (query.isEmpty) return true;
      final surah = allSurahs.firstWhere(
        (s) => s.id == b.surahId,
        orElse: () => allSurahs.first,
      );
      final ayah = surah.verses.firstWhere(
        (v) => v.id == b.ayahNumber,
        orElse: () => surah.verses.first,
      );

      final matchSurah = surah.name.toLowerCase().contains(query);
      final matchAyahNum = b.ayahNumber.toString() == query;
      final matchPageNum = b.pageNumber.toString() == query;
      final matchAyahText = ayah.text.toLowerCase().contains(query);
      final matchNote = (b.note ?? '').toLowerCase().contains(query);

      return matchSurah || matchAyahNum || matchPageNum || matchAyahText || matchNote;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث باسم السورة، رقم الآية، نص الآية أو الملاحظة...',
              hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: _buildBookmarksList(
            bookmarks: results,
            collections: collections,
            allSurahs: allSurahs,
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}
