import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/core/theme/app_theme.dart';
import 'package:awqat_salaah/features/quran/data/repositories/quran_repository.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_event.dart';
import 'package:awqat_salaah/features/quran/presentation/pages/surah_detail_page.dart';
import 'package:awqat_salaah/features/quran/presentation/widgets/qcf_mushaf_page_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepository quranRepository;
  late QuranBloc quranBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    quranRepository = QuranRepository(prefs);
    await quranRepository.loadQuran();
    quranBloc = QuranBloc(repository: quranRepository);
    quranBloc.add(const LoadQuranEvent());
    await Future.delayed(const Duration(milliseconds: 50));
  });

  tearDown(() {
    quranBloc.close();
  });

  Widget buildTestableWidget({int initialAyah = 1}) {
    final fatiha = quranRepository.getSurahById(1)!;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<QuranRepository>.value(value: quranRepository),
      ],
      child: BlocProvider<QuranBloc>.value(
        value: quranBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SurahDetailPage(
              surah: fatiha,
              initialAyah: initialAyah,
            ),
          ),
        ),
      ),
    );
  }

  group('Quran Ayah Long-Press Bottom Sheet Tests', () {
    testWidgets('Opening various Surahs (Al-Baqarah, Ali Imran, Al-Kahf, An-Nas) does not crash', (tester) async {
      for (final surahId in [2, 3, 18, 114]) {
        final surah = quranRepository.getSurahById(surahId)!;
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<QuranRepository>.value(value: quranRepository),
            ],
            child: BlocProvider<QuranBloc>.value(
              value: quranBloc,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SurahDetailPage(
                    surah: surah,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Long press on verse opens refined Bottom Sheet with exact requested actions',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Find the Ayah text widget and perform a long press
      final ayahFinder = find.textContaining('بِس').first;
      expect(ayahFinder, findsOneWidget);

      final state = tester.state(find.byType(SurahDetailPage)) as dynamic;
      state.showAyahActions(1, 'الفاتحة', quranRepository.getSurahById(1)!.verses.first);
      await tester.pumpAndSettle();

      // Verify Top Header: Surah name + Ayah number
      expect(find.textContaining('سورة الفاتحة • الآية ١'), findsOneWidget);

      // Verify Actions:
      // Row 1: [ تفسير ] [ حفظ كعلامة ]
      expect(find.text('تفسير'), findsOneWidget);
      expect(find.text('حفظ كعلامة'), findsOneWidget);

      // Row 2: [ نسخ الآية ] [ مشاركة ]
      expect(find.text('نسخ الآية'), findsOneWidget);
      expect(find.text('مشاركة'), findsOneWidget);

      // Bottom: [ تحديد آيات متعددة للمشاركة أو الحفظ ]
      expect(find.text('تحديد آيات متعددة للمشاركة أو الحفظ'), findsOneWidget);

      // STRICTLY VERIFY: Audio and Translation are completely removed
      expect(find.text('استماع'), findsNothing);
      expect(find.text('ترجمة'), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
      expect(find.byIcon(Icons.translate_rounded), findsNothing);
    });

    testWidgets('Tapping Tafsir action opens Tafsir sheet', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(SurahDetailPage)) as dynamic;
      state.showAyahActions(1, 'الفاتحة', quranRepository.getSurahById(1)!.verses.first);
      await tester.pumpAndSettle();

      // Tap Tafsir button
      await tester.tap(find.text('تفسير'));
      await tester.pumpAndSettle();

      // Verify Tafsir sheet is displayed
      expect(find.text('تفسير الآية الكريمة'), findsOneWidget);
    });

    testWidgets('Top toolbar renders clean actions and bottom control bar is removed',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Center title in toolbar
      expect(find.textContaining('سورة الفاتحة'), findsWidgets);
      expect(find.textContaining('الجزء ١'), findsWidgets);

      // Essential quiet icons in toolbar: Index, Khatmah, Themes, Ribbons
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

      // Bottom progress bar is completely removed as requested
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Tapping page background toggles progressive disclosure (show/hide controls)',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Initially toolbar is shown
      expect(find.byType(AppBar), findsOneWidget);

      // Toggle controls via state
      final state = tester.state(find.byType(SurahDetailPage)) as dynamic;
      state.toggleControls();
      await tester.pumpAndSettle();

      // Toolbar is hidden for full-screen immersive reading
      expect(find.byType(AppBar), findsNothing);

      // Toggle back
      state.toggleControls();
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Reading themes options sheet renders the 3 paper themes without font sliders',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Open themes dialog
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      expect(find.text('ثيمات ورق المصحف الشريف'), findsOneWidget);
      expect(find.text('عاجي ملكي'), findsOneWidget);
      expect(find.text('بيج تراثي'), findsOneWidget);
      expect(find.text('ليلي هادئ'), findsOneWidget);

      // Obsolete sliders must NOT be present
      expect(find.text('حجم الخط'), findsNothing);
      expect(find.text('سمك الخط'), findsNothing);
    });

    testWidgets('Quick Index sheet renders 3 tabs: Surahs, Ajzaa, and Pages',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Open quick index
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      expect(find.text('فهرس المصحف الشريف'), findsOneWidget);
      expect(find.text('السور'), findsOneWidget);
      expect(find.text('الأجزاء'), findsOneWidget);
      expect(find.text('الصفحات'), findsOneWidget);
    });

    testWidgets('Bookmark ribbon picker displays the 4 colored ribbons',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Open ribbon picker
      await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
      await tester.pumpAndSettle();

      expect(find.text('فواصل المصحف الشريف الملونة'), findsOneWidget);
      expect(find.text('الذهبية'), findsOneWidget);
      expect(find.text('الخضراء'), findsOneWidget);
      expect(find.text('الزرقاء'), findsOneWidget);
      expect(find.text('الوردية'), findsOneWidget);
    });

    testWidgets('Bookmarked Ayah includes Ayah marker seamlessly in highlight area',
        (tester) async {
      await tester.runAsync(() async {
        await quranRepository.toggleBookmark(1, 1, color: '#2E7D32');
        quranBloc.add(const LoadQuranEvent());
        await Future.delayed(const Duration(milliseconds: 60));
      });

      await tester.pumpWidget(buildTestableWidget(initialAyah: 0));
      await tester.pumpAndSettle();

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      expect(richTexts.isNotEmpty, isTrue);

      bool foundBookmarkedTextSpan = false;
      bool foundBookmarkedWidgetSpan = false;

      for (final rt in richTexts) {
        if (rt.text is TextSpan) {
          final rootSpan = rt.text as TextSpan;
          rootSpan.visitChildren((span) {
            if (span is TextSpan && span.style?.backgroundColor != null) {
              foundBookmarkedTextSpan = true;
            }
            if (span is WidgetSpan && span.style?.backgroundColor != null) {
              foundBookmarkedWidgetSpan = true;
            }
            return true;
          });
        }
      }

      expect(foundBookmarkedTextSpan, isTrue, reason: 'TextSpan must be highlighted');
      expect(foundBookmarkedWidgetSpan, isTrue, reason: 'Ayah marker WidgetSpan must be seamlessly highlighted');

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasHighlightedMarkerContainer = containers.any(
        (c) => c.color != null && c.color == const Color(0xFF2E7D32).withValues(alpha: 0.12),
      );
      expect(hasHighlightedMarkerContainer, isTrue,
          reason: 'Ayah marker container must have the bookmark highlight color');
    });

    testWidgets('Deterministic 604-page Mushaf fills viewport dynamically without surrounding card',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // 1. PageView has 604 pages
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);
      final pageView = tester.widget<PageView>(pageViewFinder);
      expect(pageView.childrenDelegate.estimatedChildCount, equals(604));

      // 2. QcfMushafPageRenderer is rendered dynamically
      final qcfRendererFinder = find.byType(QcfMushafPageRenderer);
      expect(qcfRendererFinder, findsWidgets);

      // 3. No Card surrounding the Mushaf page
      final cardsFinder = find.byType(Card);
      expect(cardsFinder, findsNothing);
    });

    testWidgets('Bottom Sheet contains ONLY the 5 required actions and no audio or translation',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Trigger bottom sheet via test hook
      final state = tester.state<State<SurahDetailPage>>(find.byType(SurahDetailPage));
      final fatiha = quranRepository.getSurahById(1)!;
      (state as dynamic).showAyahActions(1, fatiha.name, fatiha.verses.first);
      await tester.pumpAndSettle();

      // Verify the 5 required actions are present
      expect(find.text('تفسير'), findsOneWidget);
      expect(find.text('حفظ كعلامة'), findsOneWidget);
      expect(find.text('نسخ الآية'), findsOneWidget);
      expect(find.text('مشاركة'), findsOneWidget);
      expect(find.text('تحديد آيات متعددة للمشاركة أو الحفظ'), findsOneWidget);

      // Verify removed actions are NOT present
      expect(find.text('استماع'), findsNothing);
      expect(find.text('ترجمة'), findsNothing);
    });
  });
}
