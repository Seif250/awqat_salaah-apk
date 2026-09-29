import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/features/quran/data/models/ayah_model.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/quran_share_composer_dialog.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/share/share_border_painter.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/share/share_footer_renderer.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/share/share_header_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quran Share Redesign - Sizing & Aspect Ratio Rules', () {
    test('Rule 1 & 3: 1080px canvas is the SOURCE OF TRUTH and base aspect ratio is 4:5', () {
      expect(ShareLayoutCalculator.kCanvasWidth, equals(1080.0));
      expect(ShareLayoutCalculator.kMinCanvasHeight, equals(1350.0));
      expect(ShareLayoutCalculator.kBaseAspectRatio, equals(4.0 / 5.0));
      expect(ShareLayoutCalculator.kContentWidth, equals(890.0));
      // Content width occupies 82.4% of canvas width
      expect(ShareLayoutCalculator.kContentWidth / ShareLayoutCalculator.kCanvasWidth, closeTo(0.824, 0.01));
    });

    test('Acceptance Test A: Short Ayah produces 1080x1350 4:5 base, and long Ayah dynamically extends', () {
      const shortAyah = AyahModel(
        id: 1,
        text: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
        juz: 30,
        page: 604,
      );

      final shortResult = ShareLayoutCalculator.calculate(
        surahName: 'الإخلاص',
        verses: [shortAyah],
      );

      expect(shortResult.totalPages, equals(1));
      final shortPage = shortResult.firstPage;
      expect(shortPage.canvasWidth, equals(1080.0));
      expect(shortPage.canvasHeight, equals(1350.0)); // Exact 4:5 base height
      expect(shortPage.aspectRatio, equals(4.0 / 5.0));

      // Long Ayah (Ayat al-Kursi 2:255, 50 words) dynamically extends height without clipping
      const ayatAlKursi = AyahModel(
        id: 255,
        text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
        juz: 3,
        page: 42,
      );

      final longResult = ShareLayoutCalculator.calculate(
        surahName: 'البقرة',
        verses: [ayatAlKursi],
      );

      final longPage = longResult.firstPage;
      expect(longPage.canvasWidth, equals(1080.0));
      expect(longPage.canvasHeight, greaterThan(1350.0)); // Dynamically extended
      expect(longPage.canvasHeight, equals(1440.0));
      expect(longPage.startAyah, equals(255));
      expect(longPage.endAyah, equals(255));
      expect(longPage.contentWidth, equals(890.0));
    });

    test('Acceptance Test B: 3–5 Ayahs produces balanced single-page composition', () {
      final fatihaVerses = [
        const AyahModel(id: 1, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', juz: 1, page: 1),
        const AyahModel(id: 2, text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', juz: 1, page: 1),
        const AyahModel(id: 3, text: 'الرَّحْمَٰنِ الرَّحِيمِ', juz: 1, page: 1),
        const AyahModel(id: 4, text: 'مَالِكِ يَوْمِ الدِّينِ', juz: 1, page: 1),
        const AyahModel(id: 5, text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', juz: 1, page: 1),
      ];

      final result = ShareLayoutCalculator.calculate(
        surahName: 'الفاتحة',
        verses: fatihaVerses,
      );

      expect(result.totalPages, equals(1));
      final page = result.firstPage;
      expect(page.canvasWidth, equals(1080.0));
      expect(page.canvasHeight, greaterThanOrEqualTo(1350.0));
      expect(page.canvasHeight, lessThanOrEqualTo(1600.0));
      expect(page.startAyah, equals(1));
      expect(page.endAyah, equals(5));
    });

    test('Acceptance Test C: Surah Al-Imran 195–200 dynamic height & footer spec', () {
      final alImranVerses = [
        const AyahModel(id: 195, text: 'فَاسْتَجَابَ لَهُمْ رَبُّهُمْ أَنِّي لَا أُضِيعُ عَمَلَ عَامِلٍ مِّنكُم مِّن ذَكَرٍ أَوْ أُنثَىٰ', juz: 4, page: 76),
        const AyahModel(id: 196, text: 'لَا يَغُرَّنَّكَ تَقَلُّبُ الَّذِينَ كَفَرُوا فِي الْبِلَادِ', juz: 4, page: 76),
        const AyahModel(id: 197, text: 'مَتَاعٌ قَلِيلٌ ثُمَّ مَأْوَاهُمْ جَهَنَّمُ ۚ وَبِئْسَ الْمِهَادُ', juz: 4, page: 76),
        const AyahModel(id: 198, text: 'لَٰكِنِ الَّذِينَ اتَّقَوْا رَبَّهُمْ لَهُمْ جَنَّاتٌ تَجْرِي مِن تَحْتِهَا الْأَنْهَارُ خَالِدِينَ فِيهَا', juz: 4, page: 76),
        const AyahModel(id: 199, text: 'وَإِنَّ مِنْ أَهْلِ الْكِتَابِ لَمَن يُؤْمِنُ بِاللَّهِ وَمَا أُنزِلَ إِلَيْكُمْ', juz: 4, page: 76),
        const AyahModel(id: 200, text: 'يَا أَيُّهَا الَّذِينَ آمَنُوا اصْبِرُوا وَصَابِرُوا وَرَابِطُوا وَاتَّقُوا اللَّهَ لَعَلَّكُمْ تُفْلِحُونَ', juz: 4, page: 76),
      ];

      final result = ShareLayoutCalculator.calculate(
        surahName: 'آل عمران',
        verses: alImranVerses,
      );

      final page = result.firstPage;
      expect(page.canvasWidth, equals(1080.0));
      expect(page.startAyah, equals(195));
      expect(page.endAyah, equals(200));
      expect(page.surahName, equals('آل عمران'));
      expect(page.canvasHeight, greaterThanOrEqualTo(1350.0));
    });

    test('Acceptance Test D: Large selection triggers multi-page splitting without compression', () {
      // Create a large 15-verse selection with lengthy text
      final largeSelection = List.generate(
        15,
        (i) => AyahModel(
          id: 10 + i,
          text: 'وَإِذْ قَالَ اللَّهُ يَا عِيسَى ابْنَ مَرْيَمَ اذْكُرْ نِعْمَتِي عَلَيْكَ وَعَلَىٰ وَالِدَتِكَ إِذْ أَيَّدتُّكَ بِرُوحِ الْقُدُسِ تُكَلِّمُ النَّاسَ فِي الْمَهْدِ وَكَهْلًا',
          juz: 7,
          page: 125,
        ),
      );

      final result = ShareLayoutCalculator.calculate(
        surahName: 'المائدة',
        verses: largeSelection,
      );

      // Should split into multiple pages because content exceeds max single page height
      expect(result.totalPages, greaterThan(1));
      for (final page in result.pages) {
        expect(page.canvasWidth, equals(1080.0));
        expect(page.canvasHeight, lessThanOrEqualTo(ShareLayoutCalculator.kMaxSinglePageHeight));
        expect(page.canvasHeight, greaterThanOrEqualTo(ShareLayoutCalculator.kMinCanvasHeight));
        expect(page.verses, isNotEmpty);
      }
      expect(result.pages.first.pageIndex, equals(1));
      expect(result.pages.first.totalPages, equals(result.totalPages));
      expect(result.pages.last.pageIndex, equals(result.totalPages));
    });
  });

  group('Quran Share Redesign - Visual Manuscript Architecture Widgets', () {
    testWidgets('QuranShareRenderer renders with exact 1080px width and warm cream background', (tester) async {
      const pageData = SharePageData(
        pageIndex: 1,
        totalPages: 1,
        verses: [
          AyahModel(id: 1, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', juz: 1, page: 1),
        ],
        startAyah: 1,
        endAyah: 1,
        surahName: 'الفاتحة',
        canvasWidth: 1080.0,
        canvasHeight: 1350.0,
        measuredTextHeight: 120.0,
        contentWidth: 890.0,
        fontSize: 38.0,
        lineHeight: 2.2,
      );

      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: QuranShareRenderer(
                pageData: pageData,
                theme: QuranShareTheme.medina,
              ),
            ),
          ),
        ),
      );

      // Verify the widget size is strictly 1080 × 1350
      final sizedBoxFinder = find.byType(SizedBox).first;
      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.width, equals(1080.0));
      expect(sizedBox.height, equals(1350.0));

      // Verify the background is the authentic warm Mushaf paper color #F6F0E4
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      expect(container.color, equals(const Color(0xFFF6F0E4)));

      // Verify header, border, and footer are present
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(ShareHeaderRenderer), findsOneWidget);
      expect(find.byType(ShareFooterRenderer), findsOneWidget);
      expect(find.text('سُورَةُ الفاتحة'), findsOneWidget);
      expect(find.text('تطبيق وِرد'), findsOneWidget);
    });

    testWidgets('Footer formats single vs range vs multi-page correctly', (tester) async {
      // 1. Single Ayah
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShareFooterRenderer(
              surahName: 'البقرة',
              startAyah: 255,
              endAyah: 255,
              pageIndex: 1,
              totalPages: 1,
            ),
          ),
        ),
      );
      expect(find.text('سورة البقرة • الآية ٢٥٥'), findsOneWidget);

      // 2. Multiple Ayahs
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShareFooterRenderer(
              surahName: 'آل عمران',
              startAyah: 195,
              endAyah: 200,
              pageIndex: 1,
              totalPages: 1,
            ),
          ),
        ),
      );
      expect(find.text('سورة آل عمران • الآيات ١٩٥–٢٠٠'), findsOneWidget);

      // 3. Multi-page indicator
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShareFooterRenderer(
              surahName: 'النساء',
              startAyah: 1,
              endAyah: 8,
              pageIndex: 1,
              totalPages: 3,
            ),
          ),
        ),
      );
      expect(find.text('سورة النساء • الآيات ١–٨ (١ / ٣)'), findsOneWidget);
    });

    test('ShareBorderPainter instantiates with primary gold and secondary gold', () {
      const painter = ShareBorderPainter(
        primaryGold: Color(0xFFB58A4A),
        secondaryGold: Color(0xFFD8C5A5),
      );
      expect(painter.primaryGold, equals(const Color(0xFFB58A4A)));
      expect(painter.secondaryGold, equals(const Color(0xFFD8C5A5)));
    });
  });
}
