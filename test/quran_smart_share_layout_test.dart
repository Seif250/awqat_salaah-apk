import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/features/quran/data/models/ayah_model.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/quran_share_composer_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranShareLayoutEngine - Candidate Evaluation & Scoring', () {
    test('Short Ayah selects 1080x1350 canvas with majestic font size >= 40px', () {
      const shortAyah = AyahModel(
        id: 1,
        text: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
        juz: 30,
        page: 604,
      );

      final result = QuranShareLayoutEngine.calculate(
        surahName: 'الإخلاص',
        verses: [shortAyah],
      );

      expect(result.totalPages, equals(1));
      final page = result.firstPage;
      expect(page.canvasWidth, equals(1080.0));
      expect(page.canvasHeight, equals(1350.0)); // Exact 4:5 ratio
      expect(page.fontSize, greaterThanOrEqualTo(40.0));
      expect(page.layoutMode, equals(QuranShareLayoutMode.continuous));
    });

    test('Symmetric short verses evaluate candidate layouts and adhere to 1080x1350', () {
      final kawtharVerses = [
        const AyahModel(id: 1, text: 'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ', juz: 30, page: 602),
        const AyahModel(id: 2, text: 'فَصَلِّ لِرَبِّكَ وَانْحَرْ', juz: 30, page: 602),
        const AyahModel(id: 3, text: 'إِنَّ شَانِئَكَ هُوَ الْأَبْتَرُ', juz: 30, page: 602),
      ];

      final result = QuranShareLayoutEngine.calculate(
        surahName: 'الكوثر',
        verses: kawtharVerses,
      );

      expect(result.totalPages, equals(1));
      final page = result.firstPage;
      expect(page.canvasWidth, equals(1080.0));
      expect(page.canvasHeight, equals(1350.0)); // Base 4:5
      expect(page.fontSize, greaterThanOrEqualTo(34.0));
    });

    test('Standard passage (Al-Fatiha 1–5) fits comfortably inside 1080x1350 without height extension', () {
      final fatihaVerses = [
        const AyahModel(id: 1, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', juz: 1, page: 1),
        const AyahModel(id: 2, text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', juz: 1, page: 1),
        const AyahModel(id: 3, text: 'الرَّحْمَٰنِ الرَّحِيمِ', juz: 1, page: 1),
        const AyahModel(id: 4, text: 'مَالِكِ يَوْمِ الدِّينِ', juz: 1, page: 1),
        const AyahModel(id: 5, text: 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', juz: 1, page: 1),
      ];

      final result = QuranShareLayoutEngine.calculate(
        surahName: 'الفاتحة',
        verses: fatihaVerses,
      );

      expect(result.totalPages, equals(1));
      final page = result.firstPage;
      expect(page.canvasWidth, equals(1080.0));
      expect(page.canvasHeight, equals(1350.0)); // Strictly 4:5 base height
      expect(page.fontSize, greaterThanOrEqualTo(34.0));
    });

    test('Single exceptionally long Ayah allows controlled extension up to 1440px maximum', () {
      const ayatAlKursi = AyahModel(
        id: 255,
        text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
        juz: 3,
        page: 42,
      );

      final result = QuranShareLayoutEngine.calculate(
        surahName: 'البقرة',
        verses: [ayatAlKursi],
      );

      expect(result.totalPages, equals(1));
      final page = result.firstPage;
      expect(page.canvasWidth, equals(1080.0));
      // Must not exceed 1440.0 exceptional ceiling
      expect(page.canvasHeight, lessThanOrEqualTo(1440.0));
      expect(page.fontSize, greaterThanOrEqualTo(28.0));
    });

    test('Multi-Ayah selection never extends height past 1350px; splits evenly across pages', () {
      final largeSelection = List.generate(
        14,
        (i) => AyahModel(
          id: 10 + i,
          text: 'وَإِذْ قَالَ اللَّهُ يَا عِيسَى ابْنَ مَرْيَمَ اذْكُرْ نِعْمَتِي عَلَيْكَ وَعَلَىٰ وَالِدَتِكَ إِذْ أَيَّدتُّكَ بِرُوحِ الْقُدُسِ تُكَلِّمُ النَّاسَ فِي الْمَهْدِ وَكَهْلًا',
          juz: 7,
          page: 125,
        ),
      );

      final result = QuranShareLayoutEngine.calculate(
        surahName: 'المائدة',
        verses: largeSelection,
      );

      expect(result.totalPages, greaterThan(1));
      for (final page in result.pages) {
        expect(page.canvasWidth, equals(1080.0));
        // Each split page strictly adheres to 1080 x 1350
        expect(page.canvasHeight, equals(1350.0));
        expect(page.fontSize, greaterThanOrEqualTo(28.0));
      }
    });

    test('Single-word Ayah keeps balanced margins and font <= 44px', () {
      const singleWordAyah = AyahModel(
        id: 64,
        text: 'مُدْهَامَّتَانِ',
        juz: 27,
        page: 533,
      );

      final result = QuranShareLayoutEngine.calculate(
        surahName: 'الرحمن',
        verses: [singleWordAyah],
      );

      expect(result.totalPages, equals(1));
      final page = result.firstPage;
      expect(page.canvasHeight, equals(1350.0));
      expect(page.fontSize, lessThanOrEqualTo(44.0));
    });

    test('Ayat Al-Dayn (2:282) stress test fits single image under 1440px ceiling', () {
      const ayatAlDayn = AyahModel(
        id: 282,
        text: 'يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا تَدَايَنتُم بِدَيْنٍ إِلَىٰ أَجَلٍ مُّسَمًّى فَاكْتُبُوهُ ۚ وَلْيَكْتُب بَّيْنَكُمْ كَاتِبٌ بِالْعَدْلِ ۚ وَلَا يَأْبَ كَاتِبٌ أَن يَكْتُبَ كَمَا عَلَّمَهُ اللَّهُ ۚ فَلْيَكْتُبْ وَلْيُمْلِلِ الَّذِي عَلَيْهِ الْحَقُّ وَلْيَتَّقِ اللَّهَ رَبَّهُ وَلَا يَبْخَسْ مِنْهُ شَيْئًا ۚ فَإِن كَانَ الَّذِي عَلَيْهِ الْحَقُّ سَفِيهًا أَوْ ضَعِيفًا أَوْ لَا يَسْتَطِيعُ أَن يُمِلَّ هُوَ فَلْيُمْلِلْ وَلِيُّهُ بِالْعَدْلِ ۚ وَاسْتَشْهِدُوا شَهِيدَيْنِ مِن رِّجَالِكُمْ ۖ فَإِن لَّمْ يَكُونَا رَجُلَيْنِ فَرَجُلٌ وَامْرَأَتَانِ مِمَّن تَرْضَوْنَ مِنَ الشُّهَدَاءِ أَن تَضِلَّ إِحْدَاهُمَا فَتُذَكِّرَ إِحْدَاهُمَا الْأُخْرَىٰ ۚ وَلَا يَأْبَ الشُّهَدَاءُ إِذَا مَا دُعُوا ۚ وَلَا تَسْأَمُوا أَن تَكْتُبُوهُ صَغِيرًا أَوْ كَبِيرًا إِلَىٰ أَجَلِهِ ۚ ذَٰلِكُمْ أَقْسَطُ عِندَ اللَّهِ وَأَقْوَمُ لِلشَّهَادَةِ وَأَدْنَىٰ أَلَّا تَرْتَابُوا ۖ إِلَّا أَن تَكُونَ تِجَارَةً حَاضِرَةً تُدِيرُونَهَا بَيْنَكُمْ فَلَيْسَ عَلَيْكُمْ جُنَاحٌ أَلَّا تَكْتُبُوهَا ۗ وَأَشْهِدُوا إِذَا تَبَايَعْتُمْ ۚ وَلَا يُضَارَّ كَاتِبٌ وَلَا شَهِيدٌ ۚ وَإِن تَفْعَلُوا فَإِنَّهُ فُسُوقٌ بِكُمْ ۗ وَاتَّقُوا اللَّهَ ۖ وَيُعَلِّمُكُمُ اللَّهُ ۗ وَاللَّهُ بِكُلِّ شَيْءٍ عَلِيمٌ',
        juz: 3,
        page: 48,
      );

      final result = QuranShareLayoutEngine.calculate(
        surahName: 'البقرة',
        verses: [ayatAlDayn],
      );

      expect(result.totalPages, equals(1));
      final page = result.firstPage;
      // Single long verse extends up to 1440px maximum
      expect(page.canvasHeight, lessThanOrEqualTo(1440.0));
      expect(page.canvasHeight, greaterThanOrEqualTo(1350.0));
      expect(page.fontSize, greaterThanOrEqualTo(28.0));
    });

    test('Multi-page typography consistency avoids jarring font size disparity across adjacent pages', () {
      final variedVerses = [
        const AyahModel(id: 1, text: 'قُلْ هُوَ اللَّهُ أَحَدٌ', juz: 30, page: 604),
        const AyahModel(id: 2, text: 'اللَّهُ الصَّمَدُ', juz: 30, page: 604),
        const AyahModel(id: 3, text: 'لَمْ يَلِدْ وَلَمْ يُولَدْ', juz: 30, page: 604),
        const AyahModel(id: 4, text: 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ', juz: 30, page: 604),
        for (int i = 5; i <= 18; i++)
          AyahModel(
            id: i,
            text: 'يَا أَيُّهَا الَّذِينَ آمَنُوا إِذَا قُمْتُمْ إِلَى الصَّلَاةِ فَاغْسِلُوا وُجُوهَكُمْ وَأَيْدِيَكُمْ إِلَى الْمَرَافِقِ وَامْسَحُوا بِرُءُوسِكُمْ وَأَرْجُلَكُمْ إِلَى الْكَعْبَيْنِ $i',
            juz: 6,
            page: 108,
          ),
      ];

      final result = QuranShareLayoutEngine.calculate(
        surahName: 'المائدة',
        verses: variedVerses,
      );

      expect(result.totalPages, greaterThan(1));
      final fontSizes = result.pages.map((p) => p.fontSize).toList();
      final minFont = fontSizes.reduce((a, b) => a < b ? a : b);
      final maxFont = fontSizes.reduce((a, b) => a > b ? a : b);
      // Font difference across pages must be harmonized and bounded (<= 4pt)
      expect(maxFont - minFont, lessThanOrEqualTo(4.0));
    });
  });

  group('QuranShareComposerDialog - UI Hierarchy & Controls Verification', () {
    testWidgets('Renders Hero Range Selector and verifies removal of quick chips and manual font buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final items = [
        const QuranAyahShareItem(
          surahId: 1,
          surahName: 'الفاتحة',
          ayah: AyahModel(id: 1, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', juz: 1, page: 1),
        ),
        const QuranAyahShareItem(
          surahId: 1,
          surahName: 'الفاتحة',
          ayah: AyahModel(id: 2, text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', juz: 1, page: 1),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranShareComposerDialog(
              items: items,
              surahId: 1,
              surahName: 'الفاتحة',
              initialStartAyah: 1,
              initialEndAyah: 2,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify Hero Range Selector labels are present
      expect(find.text('مِنْ آيَة'), findsOneWidget);
      expect(find.text('إِلَى آيَة'), findsOneWidget);

      // 2. Verify quick range buttons are REMOVED
      expect(find.text('آية واحدة'), findsNothing);
      expect(find.text('+3 آيات'), findsNothing);
      expect(find.text('+5 آيات'), findsNothing);
      expect(find.text('+10 آيات'), findsNothing);

      // 3. Verify manual font controls (A- / A+ / 22) are REMOVED
      expect(find.byIcon(Icons.text_decrease_rounded), findsNothing);
      expect(find.byIcon(Icons.text_increase_rounded), findsNothing);

      // 4. Verify the updated primary button label: «مشاركة الصورة»
      expect(find.text('مشاركة الصورة'), findsOneWidget);

      // 5. Verify minimal top bar contains theme picker trigger
      expect(find.byType(PopupMenuButton<QuranShareTheme>), findsOneWidget);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });
  });
}
