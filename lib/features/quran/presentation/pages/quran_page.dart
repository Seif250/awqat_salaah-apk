import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numbers.dart';
import '../../../../core/utils/page_transitions.dart';
import '../../data/repositories/quran_repository.dart';
import '../bloc/quran_bloc.dart';
import '../bloc/quran_event.dart';
import '../bloc/quran_state.dart';
import '../widgets/juz_list_view.dart';
import '../widgets/quran_last_read_card.dart';
import '../widgets/surah_card.dart';
import 'surah_detail_page.dart';
import 'bookmarks_page.dart';

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs: سور, أجزاء, علامات

    // Ensure Quran is loaded
    final bloc = context.read<QuranBloc>();
    if (bloc.state is QuranInitial) {
      bloc.add(const LoadQuranEvent());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final qState = context.watch<QuranBloc>().state;
    final bookmarksCount = qState is QuranLoaded ? qState.bookmarks.length : 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.collections_bookmark_outlined),
            tooltip: 'العلامات والمجموعات',
            onPressed: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(page: const BookmarksPage()),
              );
            },
          ),
        ],
        title: Text(
          'القرآن الكريم',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF14241B)
                  : const Color(0xFFE9F0EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder.withValues(alpha: 0.8),
                  width: 0.8,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              dividerColor: Colors.transparent,
              labelColor: isDark ? AppColors.accentGoldLight : AppColors.primary,
              unselectedLabelColor: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.5,
              ),
              labelPadding: EdgeInsets.zero,
              tabs: [
                const Tab(text: 'السور'),
                const Tab(text: 'الأجزاء'),
                Tab(
                  text: bookmarksCount > 0
                      ? 'العلامات (${toArabicDigits(bookmarksCount)})'
                      : 'العلامات',
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<QuranBloc, QuranState>(
        builder: (context, state) {
          if (state is QuranLoading || state is QuranInitial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.accentGold),
                  const SizedBox(height: 16),
                  Text(
                    'جارٍ تحميل المصحف الشريف...',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is QuranError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<QuranBloc>().add(const LoadQuranEvent());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is QuranLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Surahs list
                _buildSurahsTab(state, isDark),

                // Tab 2: Ajzaa list
                JuzListView(
                  surahs: state.allSurahs,
                  onJuzSelected: (surah, targetAyah) {
                    Navigator.push(
                      context,
                      FadeSlidePageRoute(
                        page: SurahDetailPage(
                          surah: surah,
                          initialAyah: targetAyah,
                        ),
                      ),
                    );
                  },
                ),

                // Tab 3: Bookmarks
                _buildBookmarksTab(state, isDark),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSurahsTab(QuranLoaded state, bool isDark) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<QuranBloc>().add(SearchQuranEvent(query));
              },
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة بالاسم أو الرقم...',
                hintStyle: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          context.read<QuranBloc>().add(const SearchQuranEvent(''));
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.8,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.accentGold : AppColors.primary,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Expanded List with optional Last Read Header
        Expanded(
          child: state.filteredSurahs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: isDark ? Colors.white30 : Colors.black26,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لم يتم العثور على نتائج للبحث',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 88),
                  itemCount: state.filteredSurahs.length + (state.lastRead != null && state.searchQuery.isEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show LastReadCard as first item if available
                    if (state.lastRead != null && state.searchQuery.isEmpty) {
                      if (index == 0) {
                        return QuranLastReadCard(
                          lastRead: state.lastRead!,
                          onTap: () {
                            final targetSurah = state.allSurahs.firstWhere(
                              (s) => s.id == state.lastRead!.surahId,
                              orElse: () => state.allSurahs.first,
                            );
                            Navigator.push(
                              context,
                              FadeSlidePageRoute(
                                page: SurahDetailPage(
                                  surah: targetSurah,
                                  initialAyah: state.lastRead!.ayahId,
                                ),
                              ),
                            );
                          },
                        );
                      }
                      index -= 1;
                    }

                    final surah = state.filteredSurahs[index];
                    return SurahCard(
                      surah: surah,
                      onTap: () {
                        Navigator.push(
                          context,
                          FadeSlidePageRoute(
                            page: SurahDetailPage(surah: surah),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBookmarksTab(QuranLoaded state, bool isDark) {
    final repo = context.read<QuranRepository>();
    final bookmarks = state.bookmarks.toList();

    // Parse bookmarks and resolve names
    final bookmarkData = <Map<String, dynamic>>[];
    for (final bk in bookmarks) {
      final parts = bk.split(':');
      if (parts.length != 2) continue;
      final surahId = int.tryParse(parts[0]);
      final ayahId = int.tryParse(parts[1]);
      if (surahId == null || ayahId == null) continue;

      final surah = repo.getSurahById(surahId);
      if (surah == null) continue;

      bookmarkData.add({
        'surahId': surahId,
        'ayahId': ayahId,
        'surahName': surah.name,
        'page': repo.getPageForAyah(surahId, ayahId),
        'key': bk,
        'surah': surah,
      });
    }

    bookmarkData.sort((a, b) {
      final cmp = (a['surahId'] as int).compareTo(b['surahId'] as int);
      if (cmp != 0) return cmp;
      return (a['ayahId'] as int).compareTo(b['ayahId'] as int);
    });

    if (bookmarkData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.accentGold.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline_rounded,
                size: 32,
                color: isDark ? AppColors.accentGold.withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد علامات مرجعية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اضغط مطولاً على أي آية لحفظها كعلامة مرجعية',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  FadeSlidePageRoute(page: const BookmarksPage()),
                );
              },
              icon: const Icon(Icons.folder_special_rounded, color: AppColors.accentGold, size: 18),
              label: Text(
                'عرض المجموعات والمجلدات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Top Shortcut to full Bookmarks & Collections Manager
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                FadeSlidePageRoute(page: const BookmarksPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF0F4F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_special_rounded,
                    color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'إدارة العلامات والمجموعات والتدبرات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 4, bottom: 88),
            itemCount: bookmarkData.length,
            itemBuilder: (context, index) {
              final bk = bookmarkData[index];
              final surah = bk['surah'] as dynamic;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      FadeSlidePageRoute(
                        page: SurahDetailPage(
                          surah: surah,
                          initialAyah: bk['ayahId'] as int,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            // Bookmark Icon
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF0F4F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder.withValues(alpha: 0.6)
                                      : AppColors.lightBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                Icons.bookmark_rounded,
                                size: 18,
                                color: isDark ? AppColors.accentGoldLight : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'سورة ${bk['surahName']}',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'الآية ${toArabicDigits(bk['ayahId'] as int)} • صفحة ${toArabicDigits(bk['page'] as int)}',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 11.5,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Delete button
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red.withValues(alpha: 0.5),
                              ),
                              onPressed: () {
                                context.read<QuranBloc>().add(
                                      ToggleBookmarkEvent(
                                        bk['surahId'] as int,
                                        bk['ayahId'] as int,
                                      ),
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 0.6,
                        indent: 64,
                        endIndent: 16,
                        color: isDark
                            ? AppColors.darkBorder.withValues(alpha: 0.4)
                            : AppColors.lightBorder.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

