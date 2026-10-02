import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awqat_salaah/features/azkar/presentation/pages/azkar_page.dart';
import 'package:awqat_salaah/features/azkar/presentation/bloc/azkar_bloc.dart';
import 'package:awqat_salaah/features/azkar/presentation/bloc/azkar_state.dart';
import 'package:awqat_salaah/features/azkar/presentation/widgets/azkar_category_bar.dart';
import 'package:awqat_salaah/features/azkar/presentation/widgets/azkar_card.dart';
import 'package:awqat_salaah/features/azkar/data/models/azkar_item_model.dart';
import 'package:awqat_salaah/features/azkar/data/models/daily_azkar_progress.dart';

class FakeAzkarBloc extends Cubit<AzkarState> implements AzkarBloc {
  FakeAzkarBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AzkarPage Redesign & Refinement Tests', () {
    late FakeAzkarBloc azkarBloc;

    final testItems = [
      const AzkarItem(
        id: 'zikr_1',
        title: 'آية الكرسي',
        arabicText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...',
        reward: 'من قرأها حين يصبح أجير من الجن حتى يمسي',
        reference: 'صحيح الترغيب',
        targetCount: 1,
        currentCount: 0,
        category: AzkarCategory.morning,
      ),
      const AzkarItem(
        id: 'zikr_2',
        title: 'سيد الاستغفار',
        arabicText: 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ...',
        reward: 'من قالها موقنا بها حين يمسي فمات من ليلته دخل الجنة',
        reference: 'صحيح البخاري',
        targetCount: 1,
        currentCount: 1,
        category: AzkarCategory.morning,
        isCompleted: true,
      ),
      const AzkarItem(
        id: 'zikr_3',
        title: 'التسبيح والتحميد',
        arabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
        reward: 'حُطت خطاياه وإن كانت مثل زبد البحر',
        reference: 'متفق عليه',
        targetCount: 100,
        currentCount: 33,
        category: AzkarCategory.morning,
      ),
    ];

    setUp(() {
      azkarBloc = FakeAzkarBloc(
        AzkarLoaded(
          selectedCategory: AzkarCategory.morning,
          currentItems: testItems,
          dailyProgress: DailyAzkarProgress(date: DailyAzkarProgress.todayKey()),
          customAzkar: const [],
          categoryCompletionRate: 1 / 3,
          morningCompletionRate: 1 / 3,
          eveningCompletionRate: 0.0,
          completedCategoryCount: 1,
          totalCategoryCount: 3,
        ),
      );
    });

    tearDown(() {
      azkarBloc.close();
    });

    Widget buildTestableWidget() {
      return MaterialApp(
        home: BlocProvider<AzkarBloc>.value(
          value: azkarBloc,
          child: const AzkarPage(),
        ),
      );
    }

    testWidgets('Renders minimal header with title and actions', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('الأذكار والورد اليومي'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsWidgets);
      expect(find.byIcon(Icons.more_vert_rounded), findsWidgets);
    });

    testWidgets('Renders lightweight segmented category tab bar', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AzkarCategoryBar), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AzkarCategoryBar), matching: find.text('أذكار الصباح')),
        findsOneWidget,
      );
      expect(find.text('أذكار المساء'), findsOneWidget);
      expect(find.text('بعد الصلاة'), findsOneWidget);
    });

    testWidgets('Renders compact, elegant Section Hero Banner', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('أذكار الصباح'), findsWidgets);
      expect(find.textContaining('مكتملة'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('Renders AzkarCard with Dhikr text as the hero and calm secondary elements', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AzkarCard), findsNWidgets(3));

      // Titles
      expect(find.text('آية الكرسي'), findsOneWidget);
      expect(find.text('سيد الاستغفار'), findsOneWidget);
      expect(find.text('التسبيح والتحميد'), findsOneWidget);

      // Dhikr Arabic texts (The Hero)
      expect(find.text('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...'), findsOneWidget);
      expect(find.text('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ'), findsOneWidget);

      // Benefit and reference
      expect(find.textContaining('من قرأها حين يصبح'), findsOneWidget);
      expect(find.text('صحيح الترغيب'), findsOneWidget);
      expect(find.text('من فضلها'), findsNWidgets(3));

      // Edit pencil action (replaces 3 dots & bookmark)
      expect(find.byIcon(Icons.mode_edit_outline_rounded), findsWidgets);

      // Counter box and repetition controls
      expect(find.textContaining('التكرار المطلوب'), findsWidgets);
      expect(find.text('0'), findsWidgets);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });

    testWidgets('Azkar cards are wrapped in ReorderableDelayedDragStartListener for long-press moving', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Verify that every AzkarCard is wrapped in a ReorderableDelayedDragStartListener
      final listenerFinder = find.byType(ReorderableDelayedDragStartListener);
      expect(listenerFinder, findsNWidgets(3));
    });
  });
}
