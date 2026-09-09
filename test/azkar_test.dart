import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/features/azkar/data/datasources/azkar_local_data.dart';
import 'package:awqat_salaah/features/azkar/data/models/azkar_item_model.dart';
import 'package:awqat_salaah/features/azkar/data/models/custom_zikr_model.dart';
import 'package:awqat_salaah/features/azkar/data/models/daily_azkar_progress.dart';
import 'package:awqat_salaah/features/azkar/data/repositories/azkar_repository.dart';
import 'package:awqat_salaah/features/azkar/presentation/bloc/azkar_bloc.dart';
import 'package:awqat_salaah/features/azkar/presentation/bloc/azkar_event.dart';
import 'package:awqat_salaah/features/azkar/presentation/bloc/azkar_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Azkar Local Data Tests', () {
    test('contains authentic Azkar for all predefined categories', () {
      final all = AzkarLocalData.defaultAzkar;
      expect(all, isNotEmpty);

      final morning = all.where((a) => a.category == AzkarCategory.morning).toList();
      final evening = all.where((a) => a.category == AzkarCategory.evening).toList();
      final postPrayer = all.where((a) => a.category == AzkarCategory.postPrayer).toList();
      final sleep = all.where((a) => a.category == AzkarCategory.sleep).toList();
      final qiyam = all.where((a) => a.category == AzkarCategory.qiyam).toList();
      final supplications = all.where((a) => a.category == AzkarCategory.supplications).toList();
      final general = all.where((a) => a.category == AzkarCategory.general).toList();

      expect(morning, isNotEmpty);
      expect(evening, isNotEmpty);
      expect(postPrayer, isNotEmpty);
      expect(sleep, isNotEmpty);
      expect(qiyam, isNotEmpty);
      expect(supplications, isNotEmpty);
      expect(general, isNotEmpty);

      // Verify each item has non-empty title and valid arabicText
      for (final item in all) {
        expect(item.id, isNotEmpty);
        expect(item.title, isNotEmpty);
        expect(item.arabicText, isNotEmpty);
        expect(item.targetCount, greaterThan(0));
      }
    });

    test('Post-Prayer category contains the 33x tasbih items', () {
      final post = AzkarLocalData.defaultAzkar
          .where((a) => a.category == AzkarCategory.postPrayer)
          .toList();

      final tasbih = post.firstWhere((a) => a.title.contains('التسبيح'));
      final tahmid = post.firstWhere((a) => a.title.contains('التحميد'));
      final takbeer = post.firstWhere((a) => a.title.contains('التكبير'));

      expect(tasbih.targetCount, equals(33));
      expect(tahmid.targetCount, equals(33));
      expect(takbeer.targetCount, equals(33));
    });

    test('Qiyam category contains the Hadith of Taarr from night', () {
      final qiyam = AzkarLocalData.defaultAzkar
          .where((a) => a.category == AzkarCategory.qiyam)
          .toList();

      final taarr = qiyam.firstWhere((a) => a.id == 'q_0');
      expect(taarr.arabicText, contains('لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ'));
      expect(taarr.arabicText, contains('سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ'));
      expect(taarr.arabicText, contains('اللَّهُمَّ اغْفِرْ لِي'));
      expect(taarr.targetCount, equals(1));
    });

    test('Supplications category contains Greatest Name and Yunus prayer', () {
      final supps = AzkarLocalData.defaultAzkar
          .where((a) => a.category == AzkarCategory.supplications)
          .toList();

      final greatestName = supps.firstWhere((a) => a.id == 'sup_1');
      expect(greatestName.arabicText, contains('الصَّمَدُ'));

      final dhulNoon = supps.firstWhere((a) => a.id == 'sup_2');
      expect(dhulNoon.arabicText, contains('لَا إِلَهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ'));
    });
  });

  group('DailyAzkarProgress Model Tests', () {
    test('JSON serialization roundtrip maintains data integrity', () {
      final progress = DailyAzkarProgress(
        date: '2026-09-09',
        itemCounts: const {'m_1': 1, 'p_3': 33},
        completedItemIds: const {'m_1', 'p_3'},
        freeTasbihCount: 100,
        totalLifetimeTasbih: 500,
      );

      final json = progress.toJson();
      final recovered = DailyAzkarProgress.fromJson(json);

      expect(recovered.date, equals('2026-09-09'));
      expect(recovered.itemCounts['p_3'], equals(33));
      expect(recovered.completedItemIds.contains('m_1'), isTrue);
      expect(recovered.freeTasbihCount, equals(100));
      expect(recovered.totalLifetimeTasbih, equals(500));
    });

    test('todayKey produces valid YYYY-MM-DD format', () {
      final key = DailyAzkarProgress.todayKey();
      final parts = key.split('-');
      expect(parts.length, equals(3));
      expect(parts[0].length, equals(4)); // Year
      expect(parts[1].length, equals(2)); // Month
      expect(parts[2].length, equals(2)); // Day
    });
  });

  group('AzkarRepository Tests', () {
    late SharedPreferences prefs;
    late AzkarRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = AzkarRepository(prefs);
    });

    test('getDailyProgress initializes fresh progress for today', () {
      final progress = repository.getDailyProgress();
      expect(progress.date, equals(DailyAzkarProgress.todayKey()));
      expect(progress.itemCounts, isEmpty);
      expect(progress.completedItemIds, isEmpty);
    });

    test('incrementCount updates count and auto-marks completed when target reached', () {
      // Increment 1
      var progress = repository.incrementCount('m_1', 1);
      expect(progress.itemCounts['m_1'], equals(1));
      expect(progress.completedItemIds.contains('m_1'), isTrue);
      expect(progress.totalLifetimeTasbih, equals(1));

      // Increment multi-target (33)
      for (int i = 1; i <= 33; i++) {
        progress = repository.incrementCount('p_3', 33);
      }
      expect(progress.itemCounts['p_3'], equals(33));
      expect(progress.completedItemIds.contains('p_3'), isTrue);
      expect(progress.totalLifetimeTasbih, equals(34));
    });

    test('toggleCompletion toggles isCompleted state', () {
      var progress = repository.toggleCompletion('m_2', 3);
      expect(progress.completedItemIds.contains('m_2'), isTrue);
      expect(progress.itemCounts['m_2'], equals(3));

      progress = repository.toggleCompletion('m_2', 3);
      expect(progress.completedItemIds.contains('m_2'), isFalse);
      expect(progress.itemCounts['m_2'], equals(0));
    });

    test('resetCategory clears counts and completions for only that category', () {
      repository.incrementCount('m_1', 1);
      repository.incrementCount('e_1', 1);

      var progress = repository.resetCategory(AzkarCategory.morning);
      expect(progress.completedItemIds.contains('m_1'), isFalse);
      expect(progress.completedItemIds.contains('e_1'), isTrue);
    });

    test('can edit existing default azkar item in repository', () async {
      final items = repository.getAllCatalogItems();
      final m1 = items.firstWhere((i) => i.id == 'm_1');

      final updatedM1 = m1.copyWith(
        title: 'أذكار الاستيقاظ المعدلة',
        targetCount: 3,
      );

      await repository.updateZikrItem(updatedM1);

      final reloaded = repository.getAllCatalogItems();
      final found = reloaded.firstWhere((i) => i.id == 'm_1');
      expect(found.title, equals('أذكار الاستيقاظ المعدلة'));
      expect(found.targetCount, equals(3));
    });

    test('can delete existing default azkar item from repository', () async {
      final initialCount = repository.getAllCatalogItems().length;
      await repository.deleteZikrItem('m_1');

      final reloaded = repository.getAllCatalogItems();
      expect(reloaded.length, equals(initialCount - 1));
      expect(reloaded.any((i) => i.id == 'm_1'), isFalse);
    });

    test('restoreDefaultAzkar restores all deleted system azkar', () async {
      await repository.deleteZikrItem('m_1');
      await repository.deleteZikrItem('e_1');
      expect(repository.getAllCatalogItems().any((i) => i.id == 'm_1'), isFalse);

      await repository.restoreDefaultAzkar();

      final restored = repository.getAllCatalogItems();
      expect(restored.any((i) => i.id == 'm_1'), isTrue);
      expect(restored.any((i) => i.id == 'e_1'), isTrue);
    });

    test('custom azkar can be added, listed, and deleted', () async {
      final custom = CustomZikr(
        id: 'c_test_1',
        title: 'صلاة على النبي',
        arabicText: 'اللهم صل وسلم على نبينا محمد',
        targetCount: 100,
        reminderHour: 4,
        reminderMinute: 30,
        isReminderEnabled: true,
        createdAt: DateTime.now(),
      );

      await repository.addCustomZikr(custom);
      var list = repository.getCustomAzkar();
      expect(list.length, equals(1));
      expect(list.first.title, equals('صلاة على النبي'));

      await repository.deleteCustomZikr('c_test_1');
      list = repository.getCustomAzkar();
      expect(list, isEmpty);
    });

    test('automatic daily reset resets daily ward but preserves lifetime total', () async {
      // Simulate yesterday's progress
      final yesterdayProgress = DailyAzkarProgress(
        date: '2026-09-08',
        itemCounts: const {'m_1': 1},
        completedItemIds: const {'m_1'},
        freeTasbihCount: 50,
        totalLifetimeTasbih: 150,
      );
      await repository.saveDailyProgress(yesterdayProgress);

      // Now query today's progress
      final todayProgress = repository.getDailyProgress();
      expect(todayProgress.date, equals(DailyAzkarProgress.todayKey()));
      expect(todayProgress.itemCounts, isEmpty); // Daily reset!
      expect(todayProgress.completedItemIds, isEmpty); // Daily reset!
      expect(todayProgress.freeTasbihCount, equals(0)); // Daily reset!
      expect(todayProgress.totalLifetimeTasbih, equals(150)); // Preserved!
    });
  });

  group('AzkarBloc Tests', () {
    late SharedPreferences prefs;
    late AzkarRepository repository;
    late AzkarBloc bloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = AzkarRepository(prefs);
      bloc = AzkarBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is AzkarInitial, then emits AzkarLoaded on LoadAzkarEvent', () async {
      expect(bloc.state, isA<AzkarInitial>());
      bloc.add(const LoadAzkarEvent(category: AzkarCategory.morning));

      await expectLater(
        bloc.stream,
        emits(isA<AzkarLoaded>().having(
          (s) => s.selectedCategory,
          'selectedCategory',
          equals(AzkarCategory.morning),
        )),
      );
    });

    test('increments zikr count and updates completion metric', () async {
      bloc.add(const LoadAzkarEvent(category: AzkarCategory.morning));
      await bloc.stream.firstWhere((s) => s is AzkarLoaded);

      bloc.add(const IncrementZikrCountEvent(id: 'm_1', targetCount: 1));

      final updatedState = await bloc.stream.firstWhere((s) => s is AzkarLoaded) as AzkarLoaded;
      final m1 = updatedState.currentItems.firstWhere((i) => i.id == 'm_1');
      expect(m1.isCompleted, isTrue);
      expect(updatedState.completedCategoryCount, greaterThanOrEqualTo(1));
    });

    test('handles editing zikr item via UpdateZikrItemEvent', () async {
      bloc.add(const LoadAzkarEvent(category: AzkarCategory.morning));
      final loaded = await bloc.stream.firstWhere((s) => s is AzkarLoaded) as AzkarLoaded;
      final m1 = loaded.currentItems.firstWhere((i) => i.id == 'm_1');

      final updated = m1.copyWith(title: 'العنوان المعدل للصباح', targetCount: 7);
      bloc.add(UpdateZikrItemEvent(updated));

      final stateAfterEdit = await bloc.stream.firstWhere(
        (s) => s is AzkarLoaded && s.currentItems.any((i) => i.id == 'm_1' && i.title == 'العنوان المعدل للصباح'),
      ) as AzkarLoaded;

      final modifiedItem = stateAfterEdit.currentItems.firstWhere((i) => i.id == 'm_1');
      expect(modifiedItem.title, equals('العنوان المعدل للصباح'));
      expect(modifiedItem.targetCount, equals(7));
    });

    test('handles deleting zikr item via DeleteZikrItemEvent', () async {
      bloc.add(const LoadAzkarEvent(category: AzkarCategory.morning));
      await bloc.stream.firstWhere((s) => s is AzkarLoaded);

      bloc.add(const DeleteZikrItemEvent('m_1'));

      final stateAfterDelete = await bloc.stream.firstWhere(
        (s) => s is AzkarLoaded && !s.currentItems.any((i) => i.id == 'm_1'),
      ) as AzkarLoaded;

      expect(stateAfterDelete.currentItems.any((i) => i.id == 'm_1'), isFalse);
    });

    test('handles restoring default azkar via RestoreDefaultAzkarEvent', () async {
      bloc.add(const LoadAzkarEvent(category: AzkarCategory.morning));
      await bloc.stream.firstWhere((s) => s is AzkarLoaded);

      bloc.add(const DeleteZikrItemEvent('m_1'));
      await bloc.stream.firstWhere(
        (s) => s is AzkarLoaded && !s.currentItems.any((i) => i.id == 'm_1'),
      );

      bloc.add(const RestoreDefaultAzkarEvent());
      final restoredState = await bloc.stream.firstWhere(
        (s) => s is AzkarLoaded && s.currentItems.any((i) => i.id == 'm_1'),
      ) as AzkarLoaded;

      expect(restoredState.currentItems.any((i) => i.id == 'm_1'), isTrue);
    });
  });
}
