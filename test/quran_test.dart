import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/features/quran/data/models/ayah_model.dart';
import 'package:awqat_salaah/features/quran/data/models/surah_model.dart';
import 'package:awqat_salaah/features/quran/data/models/last_read_model.dart';
import 'package:awqat_salaah/features/quran/data/models/bookmark_model.dart';
import 'package:awqat_salaah/features/quran/data/models/bookmark_collection_model.dart';
import 'package:awqat_salaah/features/quran/data/repositories/quran_repository.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_event.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quran Models Tests', () {
    test('AyahModel JSON serialization and deserialization', () {
      final ayah = AyahModel(
        id: 1,
        text: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
        juz: 1,
        page: 1,
        sajda: false,
      );

      final json = ayah.toJson();
      final fromJson = AyahModel.fromJson(json);

      expect(fromJson.id, 1);
      expect(fromJson.text, 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ');
      expect(fromJson.juz, 1);
      expect(fromJson.page, 1);
      expect(fromJson.sajda, false);
      expect(fromJson, ayah);
    });

    test('SurahModel JSON serialization and deserialization', () {
      final surah = SurahModel(
        id: 1,
        name: 'الفاتحة',
        type: 'مكية',
        totalVerses: 7,
        startPage: 1,
        juz: 1,
        verses: [
          AyahModel(
            id: 1,
            text: 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
            juz: 1,
            page: 1,
          ),
        ],
      );

      final json = surah.toJson();
      final fromJson = SurahModel.fromJson(json);

      expect(fromJson.id, 1);
      expect(fromJson.name, 'الفاتحة');
      expect(fromJson.isMeccan, true);
      expect(fromJson.totalVerses, 7);
      expect(fromJson.verses.length, 1);
      expect(fromJson, surah);
    });

    test('LastReadModel JSON serialization and deserialization', () {
      final now = DateTime.now();
      final lastRead = LastReadModel(
        surahId: 2,
        surahName: 'البقرة',
        ayahId: 255,
        page: 42,
        timestamp: now,
      );

      final json = lastRead.toJson();
      final fromJson = LastReadModel.fromJson(json);

      expect(fromJson.surahId, 2);
      expect(fromJson.surahName, 'البقرة');
      expect(fromJson.ayahId, 255);
      expect(fromJson.page, 42);
      expect(
        fromJson.timestamp.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      );
    });

    test('BookmarkModel JSON serialization and deserialization', () {
      final now = DateTime.now();
      final bookmark = BookmarkModel(
        id: 'bk_2_153',
        ayahId: 160,
        surahId: 2,
        ayahNumber: 153,
        pageNumber: 24,
        color: '#D4AF37',
        note: 'آية الصبر والصلاة',
        collectionIds: ['col_fav', 'col_patience'],
        createdAt: now,
        updatedAt: now,
      );

      final json = bookmark.toJson();
      final fromJson = BookmarkModel.fromJson(json);

      expect(fromJson.id, 'bk_2_153');
      expect(fromJson.ayahId, 160);
      expect(fromJson.surahId, 2);
      expect(fromJson.ayahNumber, 153);
      expect(fromJson.pageNumber, 24);
      expect(fromJson.color, '#D4AF37');
      expect(fromJson.note, 'آية الصبر والصلاة');
      expect(fromJson.collectionIds, contains('col_patience'));
      expect(fromJson.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('BookmarkCollectionModel JSON serialization and deserialization', () {
      final now = DateTime.now();
      final col = BookmarkCollectionModel(
        id: 'col_patience',
        name: 'آيات الصبر',
        color: '#2E7D32',
        createdAt: now,
        updatedAt: now,
      );

      final json = col.toJson();
      final fromJson = BookmarkCollectionModel.fromJson(json);

      expect(fromJson.id, 'col_patience');
      expect(fromJson.name, 'آيات الصبر');
      expect(fromJson.color, '#2E7D32');
    });
  });

  group('QuranRepository Tests', () {
    late SharedPreferences prefs;
    late QuranRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = QuranRepository(prefs);
    });

    test('Loads Quran asset data correctly with 114 Surahs', () async {
      final surahs = await repository.loadQuran();

      expect(surahs.length, 114);
      expect(surahs.first.name, 'الفاتحة');
      expect(surahs.first.totalVerses, 7);
      expect(surahs.last.name, 'الناس');
      expect(surahs.last.totalVerses, 6);
    });

    test('getSurahById returns exact Surah', () async {
      await repository.loadQuran();

      final fatiha = repository.getSurahById(1);
      expect(fatiha, isNotNull);
      expect(fatiha!.name, 'الفاتحة');

      final baqarah = repository.getSurahById(2);
      expect(baqarah, isNotNull);
      expect(baqarah!.name, 'البقرة');
      expect(baqarah.totalVerses, 286);
    });

    test('searchSurahs matches normalized names and numbers', () async {
      await repository.loadQuran();

      // Search by exact name
      final results1 = repository.searchSurahs('الكهف');
      expect(results1.any((s) => s.id == 18), true);

      // Search by number
      final results2 = repository.searchSurahs('18');
      expect(results2.length, 1);
      expect(results2.first.id, 18);

      // Search normalized (without hamza/alef difference)
      final results3 = repository.searchSurahs('اخلاص');
      expect(results3.any((s) => s.name == 'الإخلاص'), true);
    });

    test('saveLastRead and getLastRead persistence roundtrip', () async {
      expect(repository.getLastRead(), isNull);

      final entry = LastReadModel(
        surahId: 36,
        surahName: 'يس',
        ayahId: 1,
        page: 440,
        timestamp: DateTime.now(),
      );

      await repository.saveLastRead(entry);

      final loaded = repository.getLastRead();
      expect(loaded, isNotNull);
      expect(loaded!.surahId, 36);
      expect(loaded.surahName, 'يس');
      expect(loaded.ayahId, 1);
    });

    test('Font size preference clamp and storage', () async {
      expect(repository.getFontSize(), 23.0);

      await repository.setFontSize(28.0);
      expect(repository.getFontSize(), 28.0);

      // Clamps to min/max
      await repository.setFontSize(50.0);
      expect(repository.getFontSize(), 36.0);

      await repository.setFontSize(10.0);
      expect(repository.getFontSize(), 16.0);
    });

    test('toggleBookmark adds and removes bookmarks', () async {
      expect(repository.isBookmarked(1, 1), false);

      final added = await repository.toggleBookmark(1, 1);
      expect(added, true);
      expect(repository.isBookmarked(1, 1), true);

      final removed = await repository.toggleBookmark(1, 1);
      expect(removed, false);
      expect(repository.isBookmarked(1, 1), false);
    });

    test('Rich Bookmark CRUD and collections roundtrip', () async {
      final defaultCols = repository.getCollections();
      expect(defaultCols.isNotEmpty, true);
      expect(defaultCols.any((c) => c.name == 'آيات مفضلة'), true);

      // Add a rich bookmark
      final now = DateTime.now();
      final bookmark = BookmarkModel(
        id: '2:153',
        ayahId: 153,
        surahId: 2,
        ayahNumber: 153,
        pageNumber: 24,
        color: '#D4AF37',
        note: 'يا أيها الذين آمنوا استعينوا بالصبر والصلاة',
        collectionIds: [defaultCols.first.id],
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveRichBookmark(bookmark);
      final bookmarks = repository.getRichBookmarks();
      expect(bookmarks.length, 1);
      expect(bookmarks.first.surahId, 2);
      expect(bookmarks.first.ayahNumber, 153);
      expect(repository.getBookmark(2, 153), isNotNull);

      // Create new collection
      final newCol = BookmarkCollectionModel(
        id: 'col_dua',
        name: 'آيات الدعاء',
        color: '#1B5E20',
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveCollection(newCol);
      expect(repository.getCollections().any((c) => c.id == newCol.id), true);

      // Add Ayah to collection
      await repository.addAyahToCollection(2, 153, newCol.id);
      final updated = repository.getBookmark(2, 153);
      expect(updated!.collectionIds.contains(newCol.id), true);

      // Delete bookmark
      await repository.removeRichBookmark(2, 153);
      expect(repository.getBookmark(2, 153), isNull);
    });
  });

  group('QuranBloc Tests', () {
    late SharedPreferences prefs;
    late QuranRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = QuranRepository(prefs);
    });

    test('Initial state is QuranInitial, then emits QuranLoaded on LoadQuranEvent', () async {
      final bloc = QuranBloc(repository: repository);
      expect(bloc.state, isA<QuranInitial>());

      bloc.add(const LoadQuranEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<QuranLoading>(),
          isA<QuranLoaded>().having(
            (s) => s.allSurahs.length,
            'allSurahs length',
            114,
          ),
        ]),
      );

      await bloc.close();
    });

    test('SearchQuranEvent filters surahs list in QuranLoaded', () async {
      final bloc = QuranBloc(repository: repository);
      bloc.add(const LoadQuranEvent());

      // Wait for loaded
      await bloc.stream.firstWhere((s) => s is QuranLoaded);

      bloc.add(const SearchQuranEvent('الكهف'));

      await expectLater(
        bloc.stream,
        emits(
          isA<QuranLoaded>().having(
            (s) => s.filteredSurahs.map((x) => x.id).contains(18),
            'contains Surah Al-Kahf',
            true,
          ),
        ),
      );

      await bloc.close();
    });

    test('ChangeFontSizeEvent updates fontSize state', () async {
      final bloc = QuranBloc(repository: repository);
      bloc.add(const LoadQuranEvent());
      await bloc.stream.firstWhere((s) => s is QuranLoaded);

      bloc.add(const ChangeFontSizeEvent(30.0));

      await expectLater(
        bloc.stream,
        emits(
          isA<QuranLoaded>().having((s) => s.fontSize, 'fontSize', 30.0),
        ),
      );

      await bloc.close();
    });

    test('SaveRichBookmarkEvent updates richBookmarks in QuranLoaded', () async {
      final bloc = QuranBloc(repository: repository);
      bloc.add(const LoadQuranEvent());
      await bloc.stream.firstWhere((s) => s is QuranLoaded);

      final now = DateTime.now();
      final bookmark = BookmarkModel(
        id: 'bk_3_139',
        ayahId: 432,
        surahId: 3,
        ayahNumber: 139,
        pageNumber: 67,
        createdAt: now,
        updatedAt: now,
      );

      bloc.add(SaveRichBookmarkEvent(bookmark));

      await expectLater(
        bloc.stream,
        emits(
          isA<QuranLoaded>().having(
            (s) => s.richBookmarks.any((b) => b.surahId == 3 && b.ayahNumber == 139),
            'has rich bookmark for 3:139',
            true,
          ),
        ),
      );

      await bloc.close();
    });
  });
}
