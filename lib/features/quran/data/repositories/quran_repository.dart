import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';
import '../models/last_read_model.dart';
import '../models/mushaf_page_model.dart';
import '../models/bookmark_model.dart';
import '../models/bookmark_collection_model.dart';

class QuranRepository {
  final SharedPreferences _prefs;
  List<SurahModel>? _cachedSurahs;
  Map<int, MushafPageModel>? _pagesCache;

  static const String _keyLastRead = 'quran_last_read';
  static const String _keyFontSize = 'quran_font_size';
  static const String _keyFontWeight = 'quran_font_weight';
  static const String _keyContinuousMode = 'quran_continuous_mode';
  static const String _keyBookmarks = 'quran_bookmarks';
  static const String _keyRichBookmarks = 'quran_rich_bookmarks';
  static const String _keyCollections = 'quran_bookmark_collections';

  static final List<BookmarkCollectionModel> _defaultCollections = [
    BookmarkCollectionModel(
      id: 'fav',
      name: 'آيات مفضلة',
      color: '#D4AF37', // Gold
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    BookmarkCollectionModel(
      id: 'patience',
      name: 'آيات الصبر',
      color: '#2E7D32', // Emerald
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    BookmarkCollectionModel(
      id: 'dua',
      name: 'أدعية قرآنية',
      color: '#1976D2', // Blue
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    BookmarkCollectionModel(
      id: 'hifz',
      name: 'الحفظ والمراجعة',
      color: '#7B1FA2', // Purple
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
    BookmarkCollectionModel(
      id: 'important',
      name: 'آيات هامة',
      color: '#C2185B', // Ruby / Crimson
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  ];

  QuranRepository(this._prefs);

  List<SurahModel>? get cachedSurahs => _cachedSurahs;
  Map<int, MushafPageModel>? get pagesCache => _pagesCache;

  /// Loads all 114 Surahs from the optimized Arabic JSON asset.
  Future<List<SurahModel>> loadQuran() async {
    if (_cachedSurahs != null && _cachedSurahs!.isNotEmpty) {
      return _cachedSurahs!;
    }

    try {
      final rawJsonString = await rootBundle.loadString('assets/data/quran.json');
      final jsonString = rawJsonString.replaceAll('\u2009', ' ');
      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      _cachedSurahs = list
          .map((item) => SurahModel.fromJson(item as Map<String, dynamic>))
          .toList();
      _buildPagesCache();
      return _cachedSurahs!;
    } catch (e) {
      final metaString = await rootBundle.loadString('assets/data/surahs_meta.json');
      final List<dynamic> metaList = json.decode(metaString) as List<dynamic>;
      _cachedSurahs = metaList
          .map((item) => SurahModel.fromJson(item as Map<String, dynamic>))
          .toList();
      _buildPagesCache();
      return _cachedSurahs!;
    }
  }

  void _buildPagesCache() {
    if (_cachedSurahs == null) return;
    _pagesCache = {};

    final Map<int, List<Map<String, dynamic>>> pageGroups = {};
    for (final surah in _cachedSurahs!) {
      for (final ayah in surah.verses) {
        pageGroups.putIfAbsent(ayah.page, () => []).add({
          'surah': surah,
          'ayah': ayah,
        });
      }
    }

    for (int p = 1; p <= 604; p++) {
      final items = pageGroups[p] ?? [];
      if (items.isEmpty) continue;

      final List<MushafPageSegment> segments = [];
      SurahModel? currentSurah;
      List<AyahModel> currentVerses = [];
      bool startsCurrentSurah = false;

      for (final item in items) {
        final surah = item['surah'] as SurahModel;
        final ayah = item['ayah'] as AyahModel;

        if (currentSurah == null || currentSurah.id != surah.id) {
          if (currentSurah != null && currentVerses.isNotEmpty) {
            segments.add(MushafPageSegment(
              surahId: currentSurah.id,
              surahName: currentSurah.name,
              startsSurah: startsCurrentSurah,
              verses: List.unmodifiable(currentVerses),
            ));
          }
          currentSurah = surah;
          currentVerses = [ayah];
          startsCurrentSurah = ayah.id == 1;
        } else {
          currentVerses.add(ayah);
          if (ayah.id == 1) startsCurrentSurah = true;
        }
      }

      if (currentSurah != null && currentVerses.isNotEmpty) {
        segments.add(MushafPageSegment(
          surahId: currentSurah.id,
          surahName: currentSurah.name,
          startsSurah: startsCurrentSurah,
          verses: List.unmodifiable(currentVerses),
        ));
      }

      final firstAyah = (items.first['ayah'] as AyahModel);
      final juz = firstAyah.juz;
      final hizb = ((p - 1) / 10).floor() + 1;
      final primarySurah = (items.first['surah'] as SurahModel).name;

      _pagesCache![p] = MushafPageModel(
        pageNumber: p,
        juz: juz,
        hizb: hizb.clamp(1, 60),
        surahName: primarySurah,
        segments: segments,
      );
    }
  }

  MushafPageModel? getPage(int pageNumber) {
    if (_pagesCache == null) _buildPagesCache();
    return _pagesCache?[pageNumber];
  }

  int getPageForSurah(int surahId) {
    final surah = getSurahById(surahId);
    return surah?.startPage ?? 1;
  }

  int getPageForAyah(int surahId, int ayahId) {
    final surah = getSurahById(surahId);
    if (surah == null) return 1;
    final ayah = surah.verses.firstWhere(
      (v) => v.id == ayahId,
      orElse: () => surah.verses.first,
    );
    return ayah.page;
  }

  /// Get a single Surah by ID (1-114).
  SurahModel? getSurahById(int id) {
    if (_cachedSurahs == null) return null;
    try {
      return _cachedSurahs!.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search Surahs by name or number with normalized Arabic text matching.
  List<SurahModel> searchSurahs(String query) {
    if (_cachedSurahs == null) return [];
    final cleanQuery = _normalizeArabic(query.trim());
    if (cleanQuery.isEmpty) return _cachedSurahs!;

    return _cachedSurahs!.where((surah) {
      final surahName = _normalizeArabic(surah.name);
      final idMatch = surah.id.toString() == cleanQuery;
      final nameMatch = surahName.contains(cleanQuery);
      return idMatch || nameMatch;
    }).toList();
  }

  /// Get the last read position, if saved.
  LastReadModel? getLastRead() {
    final raw = _prefs.getString(_keyLastRead);
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return LastReadModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Save last read position.
  Future<void> saveLastRead(LastReadModel lastRead) async {
    await _prefs.setString(_keyLastRead, json.encode(lastRead.toJson()));
  }

  /// Quran reader font size (default: 23.0, range 16-36).
  double getFontSize() {
    return _prefs.getDouble(_keyFontSize) ?? 23.0;
  }

  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_keyFontSize, size.clamp(16.0, 36.0));
  }

  /// Quran reader font weight (default: 0.5, range 0.0-1.0 where 0=normal, 0.5=bold, 1=extra bold).
  double getFontWeight() {
    return _prefs.getDouble(_keyFontWeight) ?? 0.5;
  }

  Future<void> setFontWeight(double weight) async {
    await _prefs.setDouble(_keyFontWeight, weight.clamp(0.0, 1.0));
  }

  /// Continuous Mushaf style vs Ayah card style (default: true).
  bool isContinuousMode() {
    return _prefs.getBool(_keyContinuousMode) ?? true;
  }

  Future<void> setContinuousMode(bool value) async {
    await _prefs.setBool(_keyContinuousMode, value);
  }

  /// Legacy bookmarks (surahId:ayahId).
  Set<String> getBookmarks() {
    final list = _prefs.getStringList(_keyBookmarks) ?? [];
    return list.toSet();
  }

  bool isBookmarked(int surahId, int ayahId) {
    final key = '$surahId:$ayahId';
    return getBookmarks().contains(key);
  }

  /// Toggle bookmark with support for rich bookmark models
  Future<bool> toggleBookmark(
    int surahId,
    int ayahId, {
    String color = '#D4AF37',
    String? note,
    List<String> collectionIds = const [],
  }) async {
    final rich = getRichBookmarks();
    final existingIndex = rich.indexWhere((b) => b.surahId == surahId && b.ayahNumber == ayahId);
    final willBeBookmarked = existingIndex < 0;

    if (willBeBookmarked) {
      final page = getPageForAyah(surahId, ayahId);
      final newBookmark = BookmarkModel(
        id: '$surahId:$ayahId',
        ayahId: ayahId,
        surahId: surahId,
        ayahNumber: ayahId,
        pageNumber: page,
        color: color,
        note: note,
        collectionIds: collectionIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      rich.add(newBookmark);
    } else {
      rich.removeAt(existingIndex);
    }
    await _saveRichBookmarks(rich);
    return willBeBookmarked;
  }

  /// Rich Bookmarks CRUD
  List<BookmarkModel> getRichBookmarks() {
    final raw = _prefs.getString(_keyRichBookmarks);
    List<BookmarkModel> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = json.decode(raw) as List<dynamic>;
        list = decoded
            .map((e) => BookmarkModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Auto-migrate legacy bookmarks if rich list is empty but legacy items exist
    if (list.isEmpty) {
      final legacyList = _prefs.getStringList(_keyBookmarks) ?? [];
      if (legacyList.isNotEmpty) {
        for (final item in legacyList) {
          final parts = item.split(':');
          if (parts.length == 2) {
            final surahId = int.tryParse(parts[0]) ?? 1;
            final ayahId = int.tryParse(parts[1]) ?? 1;
            final page = getPageForAyah(surahId, ayahId);
            list.add(BookmarkModel(
              id: '$surahId:$ayahId',
              ayahId: ayahId,
              surahId: surahId,
              ayahNumber: ayahId,
              pageNumber: page,
              color: '#D4AF37',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ));
          }
        }
        _saveRichBookmarks(list);
      }
    }
    return list;
  }

  BookmarkModel? getBookmark(int surahId, int ayahId) {
    final bookmarks = getRichBookmarks();
    try {
      return bookmarks.firstWhere((b) => b.surahId == surahId && b.ayahNumber == ayahId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRichBookmark(BookmarkModel bookmark) async {
    final bookmarks = getRichBookmarks();
    final index = bookmarks.indexWhere((b) => b.surahId == bookmark.surahId && b.ayahNumber == bookmark.ayahNumber);
    if (index >= 0) {
      bookmarks[index] = bookmark;
    } else {
      bookmarks.add(bookmark);
    }
    await _saveRichBookmarks(bookmarks);
  }

  Future<void> removeRichBookmark(int surahId, int ayahId) async {
    final bookmarks = getRichBookmarks().where((b) => !(b.surahId == surahId && b.ayahNumber == ayahId)).toList();
    await _saveRichBookmarks(bookmarks);
  }

  Future<void> updateBookmarkColor(int surahId, int ayahId, String color) async {
    final bookmarks = getRichBookmarks();
    final index = bookmarks.indexWhere((b) => b.surahId == surahId && b.ayahNumber == ayahId);
    if (index >= 0) {
      bookmarks[index] = bookmarks[index].copyWith(color: color, updatedAt: DateTime.now());
      await _saveRichBookmarks(bookmarks);
    }
  }

  Future<void> updateBookmarkNote(int surahId, int ayahId, String? note) async {
    final bookmarks = getRichBookmarks();
    final index = bookmarks.indexWhere((b) => b.surahId == surahId && b.ayahNumber == ayahId);
    if (index >= 0) {
      bookmarks[index] = bookmarks[index].copyWith(note: note, updatedAt: DateTime.now());
      await _saveRichBookmarks(bookmarks);
    }
  }

  Future<void> addAyahToCollection(int surahId, int ayahId, String collectionId) async {
    final bookmarks = getRichBookmarks();
    final index = bookmarks.indexWhere((b) => b.surahId == surahId && b.ayahNumber == ayahId);
    if (index >= 0) {
      final currentCols = List<String>.from(bookmarks[index].collectionIds);
      if (!currentCols.contains(collectionId)) {
        currentCols.add(collectionId);
        bookmarks[index] = bookmarks[index].copyWith(collectionIds: currentCols, updatedAt: DateTime.now());
        await _saveRichBookmarks(bookmarks);
      }
    } else {
      final page = getPageForAyah(surahId, ayahId);
      final newBk = BookmarkModel(
        id: '$surahId:$ayahId',
        ayahId: ayahId,
        surahId: surahId,
        ayahNumber: ayahId,
        pageNumber: page,
        collectionIds: [collectionId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      bookmarks.add(newBk);
      await _saveRichBookmarks(bookmarks);
    }
  }

  Future<void> removeAyahFromCollection(int surahId, int ayahId, String collectionId) async {
    final bookmarks = getRichBookmarks();
    final index = bookmarks.indexWhere((b) => b.surahId == surahId && b.ayahNumber == ayahId);
    if (index >= 0) {
      final currentCols = List<String>.from(bookmarks[index].collectionIds)..remove(collectionId);
      bookmarks[index] = bookmarks[index].copyWith(collectionIds: currentCols, updatedAt: DateTime.now());
      await _saveRichBookmarks(bookmarks);
    }
  }

  /// Bookmark multiple selected Ayat without duplicates
  Future<void> bookmarkMultipleAyat(
    List<({int surahId, int ayahId, int page})> ayat, {
    String? collectionId,
    String color = '#D4AF37',
  }) async {
    final bookmarks = getRichBookmarks();
    final now = DateTime.now();

    for (final item in ayat) {
      final index = bookmarks.indexWhere((b) => b.surahId == item.surahId && b.ayahNumber == item.ayahId);
      if (index >= 0) {
        // Already bookmarked: attach collection if specified
        if (collectionId != null && !bookmarks[index].collectionIds.contains(collectionId)) {
          final updatedCols = List<String>.from(bookmarks[index].collectionIds)..add(collectionId);
          bookmarks[index] = bookmarks[index].copyWith(collectionIds: updatedCols, updatedAt: now);
        }
      } else {
        // Create new bookmark
        bookmarks.add(BookmarkModel(
          id: '${item.surahId}:${item.ayahId}',
          ayahId: item.ayahId,
          surahId: item.surahId,
          ayahNumber: item.ayahId,
          pageNumber: item.page,
          color: color,
          collectionIds: collectionId != null ? [collectionId] : const [],
          createdAt: now,
          updatedAt: now,
        ));
      }
    }
    await _saveRichBookmarks(bookmarks);
  }

  Future<void> _saveRichBookmarks(List<BookmarkModel> bookmarks) async {
    await _prefs.setString(_keyRichBookmarks, json.encode(bookmarks.map((b) => b.toJson()).toList()));
    final legacyList = bookmarks.map((b) => '${b.surahId}:${b.ayahNumber}').toList();
    await _prefs.setStringList(_keyBookmarks, legacyList);
  }

  /// Bookmark Collections CRUD
  List<BookmarkCollectionModel> getCollections() {
    final raw = _prefs.getString(_keyCollections);
    if (raw == null || raw.isEmpty) {
      return List.from(_defaultCollections);
    }
    try {
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((e) => BookmarkCollectionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List.from(_defaultCollections);
    }
  }

  Future<void> saveCollection(BookmarkCollectionModel collection) async {
    final collections = getCollections();
    final index = collections.indexWhere((c) => c.id == collection.id);
    if (index >= 0) {
      collections[index] = collection;
    } else {
      collections.add(collection);
    }
    await _prefs.setString(_keyCollections, json.encode(collections.map((c) => c.toJson()).toList()));
  }

  Future<void> deleteCollection(String id) async {
    final collections = getCollections().where((c) => c.id != id).toList();
    await _prefs.setString(_keyCollections, json.encode(collections.map((c) => c.toJson()).toList()));

    // Also remove reference in bookmarks
    final bookmarks = getRichBookmarks();
    bool updated = false;
    for (int i = 0; i < bookmarks.length; i++) {
      if (bookmarks[i].collectionIds.contains(id)) {
        bookmarks[i] = bookmarks[i].copyWith(
          collectionIds: bookmarks[i].collectionIds.where((cid) => cid != id).toList(),
          updatedAt: DateTime.now(),
        );
        updated = true;
      }
    }
    if (updated) {
      await _saveRichBookmarks(bookmarks);
    }
  }

  /// Helper to normalize Arabic strings (removes diacritics and unifies Alefs).
  static String _normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u0652\u0670]'), '') // remove tashkeel
        .replaceAll(RegExp(r'[إأآاٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .toLowerCase();
  }
}

