import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/features/azkar/data/datasources/azkar_local_data.dart';
import 'package:awqat_salaah/features/azkar/data/models/azkar_item_model.dart';
import 'package:awqat_salaah/features/azkar/data/models/custom_zikr_model.dart';
import 'package:awqat_salaah/features/azkar/data/models/daily_azkar_progress.dart';
import 'package:awqat_salaah/features/azkar/data/repositories/azkar_repository.dart';
import 'package:awqat_salaah/features/azkar/data/services/azkar_backup_service.dart';
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

  group('AzkarBackupService Tests', () {
    test('generateBackupJson generates structured JSON with app metadata and Azkar list', () {
      const items = [
        AzkarItem(
          id: 'custom_1',
          category: AzkarCategory.custom,
          title: 'استغفار خاص',
          arabicText: 'أستغفر الله العظيم وأتوب إليه',
          targetCount: 100,
          isCustom: true,
        ),
        AzkarItem(
          id: 'custom_2',
          category: AzkarCategory.custom,
          title: 'صلاة على النبي',
          arabicText: 'اللهم صل وسلم على نبينا محمد',
          targetCount: 10,
          isCustom: true,
        ),
      ];

      final jsonStr = AzkarBackupService.generateBackupJson(items);
      expect(jsonStr, contains('awqat_salaah'));
      expect(jsonStr, contains('custom_azkar_backup'));
      expect(jsonStr, contains('استغفار خاص'));
      expect(jsonStr, contains('صلاة على النبي'));
      expect(jsonStr, contains('100'));
    });

    test('parseBackupJson successfully parses valid wrapped JSON backup', () {
      const rawJson = '''
      {
        "app": "awqat_salaah",
        "type": "custom_azkar_backup",
        "version": 1,
        "exportedAt": "2026-09-24T12:00:00Z",
        "count": 2,
        "customAzkar": [
          {
            "id": "c_1",
            "category": "custom",
            "title": "ذكر 1",
            "arabicText": "سبحان الله وبحمده",
            "targetCount": 33,
            "isCustom": true
          },
          {
            "id": "c_2",
            "category": "custom",
            "title": "ذكر 2",
            "arabicText": "لا إله إلا الله",
            "targetCount": 100,
            "isCustom": true
          }
        ]
      }
      ''';

      final parsed = AzkarBackupService.parseBackupJson(rawJson);
      expect(parsed.length, equals(2));
      expect(parsed[0].title, equals('ذكر 1'));
      expect(parsed[0].arabicText, equals('سبحان الله وبحمده'));
      expect(parsed[0].targetCount, equals(33));
      expect(parsed[0].isCustom, isTrue);
      expect(parsed[1].targetCount, equals(100));
    });

    test('parseBackupJson successfully parses raw list format for resilience', () {
      const rawListJson = '''
      [
        {
          "id": "raw_1",
          "title": "حوقلة",
          "arabicText": "لا حول ولا قوة إلا بالله",
          "targetCount": 50
        }
      ]
      ''';

      final parsed = AzkarBackupService.parseBackupJson(rawListJson);
      expect(parsed.length, equals(1));
      expect(parsed[0].title, equals('حوقلة'));
      expect(parsed[0].arabicText, equals('لا حول ولا قوة إلا بالله'));
      expect(parsed[0].targetCount, equals(50));
      expect(parsed[0].isCustom, isTrue);
    });

    test('parseBackupJson throws FormatException on invalid or empty JSON', () {
      expect(() => AzkarBackupService.parseBackupJson(''), throwsFormatException);
      expect(() => AzkarBackupService.parseBackupJson('{invalid_json}'), throwsFormatException);
      expect(() => AzkarBackupService.parseBackupJson('{"something_else": 123}'), throwsFormatException);
    });

    test('defaultFileName generates timestamped JSON filename', () {
      final fileName = AzkarBackupService.defaultFileName();
      expect(fileName, startsWith('awqat_salaah_azkar_backup_'));
      expect(fileName, endsWith('.json'));
    });

    test('getSavedBackupDirectory and setSavedBackupDirectory save and retrieve path', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AzkarBackupService.getSavedBackupDirectory(), isNull);

      final tempDir = Directory.systemTemp.createTempSync('backup_test_dir');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      await AzkarBackupService.setSavedBackupDirectory(tempDir.path);
      final retrieved = await AzkarBackupService.getSavedBackupDirectory();
      expect(retrieved, equals(tempDir.path));

      await AzkarBackupService.resetSavedBackupDirectory();
      expect(await AzkarBackupService.getSavedBackupDirectory(), isNull);
    });

    test('exportBackupToFile writes valid JSON to custom directory', () async {
      final tempDir = Directory.systemTemp.createTempSync('backup_export_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      const items = [
        AzkarItem(
          id: 'test_export_1',
          category: AzkarCategory.custom,
          title: 'تسبيح تجريبي',
          arabicText: 'سبحان الله',
          targetCount: 33,
          isCustom: true,
        ),
      ];

      final filePath = await AzkarBackupService.exportBackupToFile(
        items,
        customDirectory: tempDir.path,
      );

      final file = File(filePath);
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      final parsed = AzkarBackupService.parseBackupJson(content);
      expect(parsed.length, equals(1));
      expect(parsed[0].title, equals('تسبيح تجريبي'));
    });
  });

  group('AzkarRepository Backup & Restore Tests', () {
    late SharedPreferences prefs;
    late AzkarRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = AzkarRepository(prefs);
    });

    test('getCustomAzkarItems returns only custom items', () async {
      final initialCustom = repo.getCustomAzkarItems();
      expect(initialCustom, isEmpty);

      await repo.addCustomZikr(CustomZikr(
        id: 'cust_1',
        title: 'ورد القرآن',
        arabicText: 'قراءة جزء يومياً',
        targetCount: 1,
        createdAt: DateTime.now(),
      ));

      final customList = repo.getCustomAzkarItems();
      expect(customList.length, equals(1));
      expect(customList.first.title, equals('ورد القرآن'));
      expect(customList.first.isCustom, isTrue);
    });

    test('importCustomAzkar merges items without duplicates when replaceExisting is false', () async {
      await repo.addCustomZikr(CustomZikr(
        id: 'existing_1',
        title: 'ذكر قديم',
        arabicText: 'الحمد لله',
        targetCount: 10,
        createdAt: DateTime.now(),
      ));

      const imported = [
        AzkarItem(
          id: 'existing_1',
          category: AzkarCategory.custom,
          title: 'ذكر قديم',
          arabicText: 'الحمد لله حمداً كثيراً',
          targetCount: 20,
          isCustom: true,
        ),
        AzkarItem(
          id: 'imported_2',
          category: AzkarCategory.custom,
          title: 'ذكر جديد',
          arabicText: 'سبحان الله العظيم',
          targetCount: 33,
          isCustom: true,
        ),
      ];

      final count = await repo.importCustomAzkar(imported, replaceExisting: false);
      expect(count, equals(2));

      final allCustom = repo.getCustomAzkarItems();
      expect(allCustom.length, equals(2));
      // existing_1 should have updated values
      final updatedExisting = allCustom.firstWhere((i) => i.id == 'existing_1');
      expect(updatedExisting.targetCount, equals(20));
      expect(updatedExisting.arabicText, equals('الحمد لله حمداً كثيراً'));
    });

    test('importCustomAzkar replaces all custom items when replaceExisting is true', () async {
      await repo.addCustomZikr(CustomZikr(
        id: 'old_1',
        title: 'ذكر سيتم حذفه',
        arabicText: 'نص قديم',
        targetCount: 5,
        createdAt: DateTime.now(),
      ));

      const imported = [
        AzkarItem(
          id: 'new_fresh_1',
          category: AzkarCategory.custom,
          title: 'ذكر مسترجع وحيد',
          arabicText: 'أستغفر الله وأتوب إليه',
          targetCount: 70,
          isCustom: true,
        ),
      ];

      final count = await repo.importCustomAzkar(imported, replaceExisting: true);
      expect(count, equals(1));

      final allCustom = repo.getCustomAzkarItems();
      expect(allCustom.length, equals(1));
      expect(allCustom.first.id, equals('new_fresh_1'));
      expect(allCustom.any((i) => i.id == 'old_1'), isFalse);
    });
  });

  group('AzkarBloc Backup & Restore Integration Tests', () {
    late SharedPreferences prefs;
    late AzkarRepository repo;
    late AzkarBloc bloc;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = AzkarRepository(prefs);
      bloc = AzkarBloc(repository: repo);
    });

    tearDown(() {
      bloc.close();
    });

    test('handles importing custom Azkar via ImportCustomAzkarEvent and sets category to custom', () async {
      bloc.add(const LoadAzkarEvent(category: AzkarCategory.morning));
      await bloc.stream.firstWhere((s) => s is AzkarLoaded);

      const importedItems = [
        AzkarItem(
          id: 'imp_1',
          category: AzkarCategory.custom,
          title: 'دعاء مسترجع',
          arabicText: 'اللهم إنك عفو تحب العفو فاعف عني',
          targetCount: 7,
          isCustom: true,
        ),
      ];

      bloc.add(const ImportCustomAzkarEvent(items: importedItems, replaceExisting: false));

      final loadedState = await bloc.stream.firstWhere(
        (s) => s is AzkarLoaded && s.selectedCategory == AzkarCategory.custom,
      ) as AzkarLoaded;

      expect(loadedState.selectedCategory, equals(AzkarCategory.custom));
      expect(loadedState.currentItems.any((i) => i.id == 'imp_1'), isTrue);
      final item = loadedState.currentItems.firstWhere((i) => i.id == 'imp_1');
      expect(item.title, equals('دعاء مسترجع'));
      expect(item.targetCount, equals(7));
    });

    test('handles reordering azkar in a category via ReorderAzkarEvent', () async {
      bloc.add(const LoadAzkarEvent(category: AzkarCategory.morning));
      final initial = await bloc.stream.firstWhere((s) => s is AzkarLoaded) as AzkarLoaded;

      final firstId = initial.currentItems[0].id;
      final secondId = initial.currentItems[1].id;

      bloc.add(const ReorderAzkarEvent(
        category: AzkarCategory.morning,
        oldIndex: 0,
        newIndex: 2,
      ));

      final reordered = await bloc.stream.firstWhere(
        (s) => s is AzkarLoaded && s.currentItems[0].id == secondId,
      ) as AzkarLoaded;

      expect(reordered.currentItems[0].id, equals(secondId));
      expect(reordered.currentItems[1].id, equals(firstId));
    });
  });

  group('Multi-Category Support Tests', () {
    test('AzkarItem matchesCategory returns true for any category in categories list', () {
      const item = AzkarItem(
        id: 'multi_1',
        category: AzkarCategory.morning,
        categories: [
          AzkarCategory.morning,
          AzkarCategory.evening,
          AzkarCategory.qiyam,
        ],
        title: 'دعاء متعدد الأوقات',
        arabicText: 'اللهم بك أصبحنا وبك أمسينا',
        targetCount: 3,
      );

      expect(item.matchesCategory(AzkarCategory.morning), isTrue);
      expect(item.matchesCategory(AzkarCategory.evening), isTrue);
      expect(item.matchesCategory(AzkarCategory.qiyam), isTrue);
      expect(item.matchesCategory(AzkarCategory.sleep), isFalse);
    });

    test('AzkarItem JSON roundtrip preserves multiple categories', () {
      const original = AzkarItem(
        id: 'multi_json',
        category: AzkarCategory.morning,
        categories: [
          AzkarCategory.morning,
          AzkarCategory.evening,
          AzkarCategory.sleep,
        ],
        title: 'ذكر متعدد',
        arabicText: 'سبحان الله وبحمده',
        targetCount: 10,
      );

      final json = original.toJson();
      final fromJson = AzkarItem.fromJson(json);

      expect(fromJson.effectiveCategories, containsAll([
        AzkarCategory.morning,
        AzkarCategory.evening,
        AzkarCategory.sleep,
      ]));
      expect(fromJson.matchesCategory(AzkarCategory.evening), isTrue);
      expect(fromJson.matchesCategory(AzkarCategory.sleep), isTrue);
    });

    test('multi-category zikr isolates progress so morning completion does NOT complete evening', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AzkarRepository(prefs);

      const multiItem = AzkarItem(
        id: 'isolated_multi_1',
        category: AzkarCategory.morning,
        categories: [AzkarCategory.morning, AzkarCategory.evening],
        title: 'ذكر مشترك',
        arabicText: 'سبحان الله وبحمده',
        targetCount: 3,
      );

      await repo.addZikrItem(multiItem);

      // Increment 3 times in morning to complete it
      repo.incrementCount(multiItem.id, multiItem.targetCount, category: AzkarCategory.morning);
      repo.incrementCount(multiItem.id, multiItem.targetCount, category: AzkarCategory.morning);
      repo.incrementCount(multiItem.id, multiItem.targetCount, category: AzkarCategory.morning);

      final progress = repo.getDailyProgress();

      // Check morning items: should be completed (3/3)
      final morningItems = repo.getCategoryItems(AzkarCategory.morning, progress);
      final morningMatch = morningItems.firstWhere((i) => i.id == multiItem.id);
      expect(morningMatch.currentCount, equals(3));
      expect(morningMatch.isCompleted, isTrue);

      // Check evening items: MUST NOT be completed (0/3)
      final eveningItems = repo.getCategoryItems(AzkarCategory.evening, progress);
      final eveningMatch = eveningItems.firstWhere((i) => i.id == multiItem.id);
      expect(eveningMatch.currentCount, equals(0));
      expect(eveningMatch.isCompleted, isFalse);
    });

    test('MoveZikrItemEvent moves item from fromIndex to toIndex directly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AzkarRepository(prefs);
      final bloc = AzkarBloc(repository: repo);

      bloc.add(const LoadAzkarEvent(category: AzkarCategory.morning));
      final initial = await bloc.stream.firstWhere((s) => s is AzkarLoaded) as AzkarLoaded;

      final firstId = initial.currentItems[0].id;
      final secondId = initial.currentItems[1].id;

      // Move index 0 to index 1
      bloc.add(const MoveZikrItemEvent(
        category: AzkarCategory.morning,
        fromIndex: 0,
        toIndex: 1,
      ));

      final moved = await bloc.stream.firstWhere(
        (s) => s is AzkarLoaded && s.currentItems[0].id == secondId,
      ) as AzkarLoaded;

      expect(moved.currentItems[0].id, equals(secondId));
      expect(moved.currentItems[1].id, equals(firstId));
      await bloc.close();
    });
  });
}
