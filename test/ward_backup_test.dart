import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/features/azkar/data/models/ward_backup_model.dart';
import 'package:awqat_salaah/features/azkar/data/models/azkar_item_model.dart';
import 'package:awqat_salaah/features/azkar/data/services/backup_service.dart';

void main() {
  group('WardBackup Versioned JSON Tests', () {
    test('Serializes and deserializes WardBackup schema v1 properly', () {
      final now = DateTime.now().toUtc().toIso8601String();
      final backup = WardBackup(
        createdAt: now,
        customAdhkar: [
          CustomDhikrBackupModel(
            id: 'uuid-1234',
            title: 'سيد الاستغفار',
            text: 'اللهم أنت ربي لا إله إلا أنت...',
            repeatCount: 3,
            categoryId: 'custom',
            source: 'صحيح البخاري',
            note: 'يقال صباحاً ومساءً',
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final jsonStr = backup.toFormattedJson();
      expect(jsonStr, contains('"format": "ward_backup"'));
      expect(jsonStr, contains('"version": 1'));
      expect(jsonStr, contains('"customAdhkar"'));
      expect(jsonStr, contains('سيد الاستغفار'));

      final parsed = WardBackup.fromJsonString(jsonStr);
      expect(parsed.format, equals('ward_backup'));
      expect(parsed.version, equals(1));
      expect(parsed.customAdhkar.length, equals(1));
      expect(parsed.customAdhkar.first.id, equals('uuid-1234'));
      expect(parsed.customAdhkar.first.title, equals('سيد الاستغفار'));
      expect(parsed.customAdhkar.first.repeatCount, equals(3));
      expect(parsed.customAdhkar.first.source, equals('صحيح البخاري'));
    });

    test('Parses legacy format backward-compatibly', () {
      const legacyJson = '''
      {
        "customAzkar": [
          {
            "id": "old_1",
            "title": "ذكر قديم",
            "arabicText": "سبحان الله وبحمده",
            "targetCount": 100
          }
        ]
      }
      ''';

      final parsed = WardBackup.fromJsonString(legacyJson);
      expect(parsed.customAdhkar.length, equals(1));
      expect(parsed.customAdhkar.first.title, equals('ذكر قديم'));
      expect(parsed.customAdhkar.first.text, equals('سبحان الله وبحمده'));
      expect(parsed.customAdhkar.first.repeatCount, equals(100));
    });

    test('Detects duplicate Adhkar by ID and by normalized Arabic text', () {
      final existingItems = [
        const AzkarItem(
          id: 'existing_id_1',
          title: 'الاستغفار',
          arabicText: 'أَسْتَغْفِرُ اللَّهَ العَظِيمَ',
          targetCount: 3,
          category: AzkarCategory.custom,
          isCustom: true,
        ),
      ];

      final now = DateTime.now().toUtc().toIso8601String();
      final backup = WardBackup(
        createdAt: now,
        customAdhkar: [
          // Duplicate by text (with/without diacritics / tashkeel)
          CustomDhikrBackupModel(
            id: 'different_id_2',
            title: 'الاستغفار',
            text: 'استغفر الله العظيم',
            repeatCount: 3,
            createdAt: now,
            updatedAt: now,
          ),
          // Completely new item
          CustomDhikrBackupModel(
            id: 'new_id_3',
            title: 'الحوقلة',
            text: 'لا حول ولا قوة إلا بالله',
            repeatCount: 10,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final analysis = BackupService.analyzeBackup(backup, existingItems);
      expect(analysis.totalItems.length, equals(2));
      expect(analysis.duplicateItems.length, equals(1));
      expect(analysis.newItems.length, equals(1));
      expect(analysis.newItems.first.title, equals('الحوقلة'));
    });
  });
}
