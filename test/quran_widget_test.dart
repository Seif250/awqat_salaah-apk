import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/core/theme/app_theme.dart';
import 'package:awqat_salaah/core/utils/arabic_numbers.dart';
import 'package:awqat_salaah/features/quran/data/models/surah_model.dart';
import 'package:awqat_salaah/features/quran/data/models/last_read_model.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/surah_card.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/quran_last_read_card.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/surah_bismillah_header.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/ayah_rosette.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/mushaf_bismillah.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/mushaf_surah_banner.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: child),
      ),
    );
  }

  group('Quran Widget Tests', () {
    test('toArabicDigits converts western numbers to Arabic-Indic digits', () {
      expect(toArabicDigits(1), '١');
      expect(toArabicDigits(114), '١١٤');
      expect(toArabicDigits(2026), '٢٠٢٦');
    });

    testWidgets('SurahCard renders Arabic name, verse count, and revelation badge',
        (tester) async {
      bool tapped = false;
      const surah = SurahModel(
        id: 1,
        name: 'الفاتحة',
        type: 'مكية',
        totalVerses: 7,
        startPage: 1,
        juz: 1,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          SurahCard(
            surah: surah,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('سورة الفاتحة'), findsOneWidget);
      expect(find.text('مكية'), findsOneWidget);
      expect(find.text('١'), findsOneWidget); // Surah number in Arabic
      expect(find.text('٧ آيات • الجزء ١ • صفحة ١'), findsOneWidget);

      await tester.tap(find.byType(SurahCard));
      expect(tapped, true);
    });

    testWidgets('QuranLastReadCard renders last read Surah, Ayah and triggers callback',
        (tester) async {
      bool tapped = false;
      final lastRead = LastReadModel(
        surahId: 18,
        surahName: 'الكهف',
        ayahId: 10,
        page: 293,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          QuranLastReadCard(
            lastRead: lastRead,
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('آخر قراءة'), findsOneWidget);
      expect(find.text('سورة الكهف • الآية ١٠'), findsOneWidget);
      expect(find.text('صفحة ٢٩٣'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);

      await tester.tap(find.text('متابعة'));
      expect(tapped, true);
    });

    testWidgets('SurahBismillahHeader renders Bismillah text',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const SurahBismillahHeader(),
        ),
      );

      expect(find.text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'), findsOneWidget);
    });

    testWidgets('AyahRosette renders arabic numerals inside floral rosette',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AyahRosette(ayahNumber: 5),
        ),
      );

      expect(find.text('٥'), findsOneWidget);
    });

    testWidgets('MushafSurahBanner renders ornamental frame and Surah name',
        (tester) async {
      const surah = SurahModel(
        id: 2,
        name: 'البقرة',
        type: 'مكية',
        totalVerses: 286,
        startPage: 2,
        juz: 1,
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const MushafSurahBanner(surah: surah),
        ),
      );

      expect(find.text('سُورَةُ البقرة'), findsOneWidget);
    });

    testWidgets('MushafBismillah renders centered calligraphic Basmalah',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const MushafBismillah(),
        ),
      );

      expect(find.text('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ'), findsOneWidget);
    });
  });
}
