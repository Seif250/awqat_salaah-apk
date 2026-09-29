import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/features/quran/data/models/qcf_page_model.dart';
import 'package:awqat_salaah/features/quran/data/models/quran_display_mode.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/quran_page_renderer.dart';
import 'package:awqat_salaah/features/quran/services/qcf_font_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quran Mushaf Parity & Explicit V4 Availability Tests', () {
    test('Font family for page is strictly distinct between V2 and V4 without silent fallback', () {
      for (final p in [1, 2, 3, 76, 604]) {
        final v2Font = QcfFontService.fontFamilyForPage(p, mode: QuranDisplayMode.normal);
        final v4Font = QcfFontService.fontFamilyForPage(p, mode: QuranDisplayMode.tajweed);

        expect(v2Font, 'QCF_P$p');
        expect(v4Font, 'QCF_V4_P$p');
        expect(v2Font, isNot(equals(v4Font)));
      }
    });

    test('Canonical Medina Mushaf Canvas geometry constants are strictly defined', () {
      expect(QuranPageRenderer.kLogicalCanvasWidth, 385.0);
      expect(QuranPageRenderer.kReadingWidth, 353.0);
      expect(QuranPageRenderer.kHeaderHeight, 28.0);
      expect(QuranPageRenderer.kFooterHeight, 26.0);
    });

    testWidgets('Tajweed V4 displays explicit controlled status when font is loading and does not silently render V2',
        (tester) async {
      final mockLines = List.generate(
        15,
        (i) => QcfLineModel(
          line: i + 1,
          type: 'text',
          words: const [
            QcfWordModel(
              location: '1:1:1',
              word: 'كلمة',
              qpcV2: '\u0041',
            ),
          ],
        ),
      );

      final mockPage = QcfPageModel(
        page: 55,
        lines: mockLines,
      );

      // Render Tajweed mode widget (font is not loaded in unit test environment)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPageRenderer.create(
              displayMode: QuranDisplayMode.tajweed,
              pageModel: mockPage,
              juz: 3,
              hizb: 5,
              surahName: 'آل عمران',
              onAyahTap: ({required int surahId, required int ayahId}) {},
              onAyahLongPress: ({required int surahId, required int ayahId}) {},
              onPageTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Must display explicit controlled loading status
      expect(find.text('جاري تحميل خط مصحف التجويد الملوّن...'), findsOneWidget);
      expect(find.text('الصفحة ٥٥'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Normal V2 renders 15 lines within single page-level FittedBox without per-line FittedBox',
        (tester) async {
      final mockLines = List.generate(
        15,
        (i) => QcfLineModel(
          line: i + 1,
          type: 'text',
          words: const [
            QcfWordModel(
              location: '1:1:1',
              word: 'الحمد',
              qpcV2: '\u0041',
            ),
          ],
        ),
      );

      final mockPage = QcfPageModel(
        page: 3,
        lines: mockLines,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPageRenderer.create(
              displayMode: QuranDisplayMode.normal,
              pageModel: mockPage,
              juz: 1,
              hizb: 1,
              surahName: 'البقرة',
              onAyahTap: ({required int surahId, required int ayahId}) {},
              onAyahLongPress: ({required int surahId, required int ayahId}) {},
              onPageTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Exactly ONE FittedBox exists at the page container level for uniform scaling
      final fittedBoxes = tester.widgetList<FittedBox>(find.byType(FittedBox)).toList();
      expect(fittedBoxes.length, 1);
      expect(fittedBoxes.first.fit, BoxFit.contain);

      // Verify Page footer contains page number 3 in RichText
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('٣'),
        ),
        findsOneWidget,
      );
    });
  });
}
