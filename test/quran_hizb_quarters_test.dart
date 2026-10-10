import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/features/quran/data/models/surah_model.dart';
import 'package:awqat_salaah/features/quran/data/quran_quarters.dart';
import 'package:awqat_salaah/features/quran/data/repositories/quran_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepository repository;
  late List<SurahModel> surahs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = QuranRepository(await SharedPreferences.getInstance());
    surahs = await repository.loadQuran();
  });

  test('table has 240 quarters in Mushaf order, all real ayat', () {
    expect(kRubAlHizbStarts.length, 240);
    for (var i = 0; i < kRubAlHizbStarts.length; i++) {
      final s = kRubAlHizbStarts[i][0];
      final a = kRubAlHizbStarts[i][1];
      final surah = repository.getSurahById(s);
      expect(surah, isNotNull, reason: 'quarter ${i + 1}');
      expect(a, inInclusiveRange(1, surah!.totalVerses),
          reason: 'quarter ${i + 1}');
      if (i > 0) {
        final prev = kRubAlHizbStarts[i - 1];
        final isAfter = s > prev[0] || (s == prev[0] && a > prev[1]);
        expect(isAfter, isTrue, reason: 'quarter ${i + 1} out of order');
      }
    }
  });

  test('every 8th quarter starts exactly where quran.json starts a juz', () {
    final juzStarts = <int, List<int>>{};
    for (final surah in surahs) {
      for (final ayah in surah.verses) {
        juzStarts.putIfAbsent(ayah.juz, () => [surah.id, ayah.id]);
      }
    }
    expect(juzStarts.length, 30);
    for (var juz = 1; juz <= 30; juz++) {
      expect(kRubAlHizbStarts[(juz - 1) * 8], juzStarts[juz],
          reason: 'juz $juz');
    }
  });

  test('hizbForAyah resolves boundaries', () {
    expect(hizbForAyah(1, 1), 1);
    expect(hizbForAyah(2, 74), 1);
    expect(hizbForAyah(2, 75), 2);
    expect(hizbForAyah(2, 142), 3);
    expect(hizbForAyah(18, 74), 30);
    expect(hizbForAyah(18, 75), 31);
    expect(hizbForAyah(114, 6), 60);
    expect(rubAlHizbForAyah(2, 25), 1);
    expect(rubAlHizbForAyah(2, 26), 2);
    expect(rubAlHizbForAyah(100, 9), 240);
  });

  test('page headers use the real hizb, consistent with the juz', () {
    var previous = 0;
    for (var p = 1; p <= 604; p++) {
      final page = repository.getPage(p)!;
      expect(page.hizb, greaterThanOrEqualTo(previous), reason: 'page $p');
      expect((page.hizb + 1) ~/ 2, page.juz, reason: 'page $p');
      previous = page.hizb;
    }
    expect(repository.getPage(1)!.hizb, 1);
    expect(repository.getPage(604)!.hizb, 60);
  });
}
