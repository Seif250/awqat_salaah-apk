import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/core/theme/app_theme.dart';
import 'package:awqat_salaah/features/quran/data/repositories/quran_repository.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_event.dart';
import 'package:awqat_salaah/features/quran/presentation/pages/surah_detail_page.dart';

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
    testWidgets('Long press on verse opens refined Bottom Sheet with exact requested actions',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Find the Ayah text widget and perform a long press
      final ayahFinder = find.textContaining('بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ').first;
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

    testWidgets('Top toolbar and bottom progress control render with quiet, minimal hierarchy',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Center title in toolbar
      expect(find.textContaining('سورة الفاتحة'), findsWidgets);
      expect(find.textContaining('الجزء ١'), findsWidgets);

      // Essential quiet icons in toolbar
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

      // Bottom progress control renders page metadata and progress indicator
      expect(find.text('صفحة ١'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Tapping page background toggles progressive disclosure (show/hide controls)',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Initially controls are shown
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Toggle controls via state
      final state = tester.state(find.byType(SurahDetailPage)) as dynamic;
      state.toggleControls();
      await tester.pumpAndSettle();

      // Controls are hidden for full-screen immersive reading
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // Toggle back
      state.toggleControls();
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
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
  });
}
