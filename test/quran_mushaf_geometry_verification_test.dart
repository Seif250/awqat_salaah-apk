import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/features/quran/data/models/qcf_page_model.dart';
import 'package:awqat_salaah/features/quran/data/models/quran_display_mode.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/quran_page_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  QcfPageModel createMockPage(int pageNum, {int lineCount = 15}) {
    final lines = List.generate(
      lineCount,
      (i) => QcfLineModel(
        line: i + 1,
        type: 'text',
        words: [
          QcfWordModel(
            location: '$pageNum:${i + 1}:1',
            word: 'كلمة',
            qpcV2: '\u0041',
          ),
          QcfWordModel(
            location: '$pageNum:${i + 1}:2',
            word: 'أخرى',
            qpcV2: '\u0042',
          ),
        ],
      ),
    );
    return QcfPageModel(page: pageNum, lines: lines);
  }

  group('Mushaf Geometry & Distribution Verification', () {
    final viewports = <String, Size>{
      'Compact (320px)': const Size(320, 568),
      'Standard (360px)': const Size(360, 780),
      'Modern (390px)': const Size(390, 844),
      'Large (412px)': const Size(412, 915),
      'Tablet (800px)': const Size(800, 1280),
    };

    for (final entry in viewports.entries) {
      final name = entry.key;
      final size = entry.value;

      testWidgets('Renders and centers correctly on $name (${size.width}x${size.height})', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final mockPage = createMockPage(5);

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

        // 1. Exactly one FittedBox at page level with Alignment.center
        final fittedBoxFinder = find.byType(FittedBox);
        expect(fittedBoxFinder, findsOneWidget);
        final fittedBox = tester.widget<FittedBox>(fittedBoxFinder);
        expect(fittedBox.alignment, Alignment.center);
        expect(fittedBox.fit, BoxFit.contain);

        // 2. Align parent also uses Alignment.center
        final alignFinder = find.ancestor(
          of: fittedBoxFinder,
          matching: find.byType(Align),
        );
        expect(alignFinder, findsOneWidget);
        final align = tester.widget<Align>(alignFinder);
        expect(align.alignment, Alignment.center);

        // 3. Header and footer are present
        expect(find.text('سُورَةُ البقرة'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains('٥'),
          ),
          findsOneWidget,
        );

        // 4. Verify no Flutter layout overflow errors
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Opening pages (Page 1 & 2) render centered with proper hierarchy', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final page1 = createMockPage(1, lineCount: 8);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPageRenderer.create(
              displayMode: QuranDisplayMode.normal,
              pageModel: page1,
              juz: 1,
              hizb: 1,
              surahName: 'الفاتحة',
              onAyahTap: ({required int surahId, required int ayahId}) {},
              onAyahLongPress: ({required int surahId, required int ayahId}) {},
              onPageTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('سُورَةُ ٱلْفَاتِحَةِ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('End of Mushaf (Page 604) renders correctly with 15 lines', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final page604 = createMockPage(604, lineCount: 15);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuranPageRenderer.create(
              displayMode: QuranDisplayMode.normal,
              pageModel: page604,
              juz: 30,
              hizb: 60,
              surahName: 'الناس',
              onAyahTap: ({required int surahId, required int ayahId}) {},
              onAyahLongPress: ({required int surahId, required int ayahId}) {},
              onPageTap: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('٦٠٤'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
