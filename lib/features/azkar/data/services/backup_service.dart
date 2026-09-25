import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../models/azkar_item_model.dart';
import '../models/ward_backup_model.dart';
import '../repositories/azkar_repository.dart';

/// Result analysis when validating an imported backup against current records.
class BackupAnalysisResult {
  final WardBackup backup;
  final List<CustomDhikrBackupModel> totalItems;
  final List<CustomDhikrBackupModel> newItems;
  final List<CustomDhikrBackupModel> duplicateItems;

  const BackupAnalysisResult({
    required this.backup,
    required this.totalItems,
    required this.newItems,
    required this.duplicateItems,
  });

  bool get hasDuplicates => duplicateItems.isNotEmpty;
}

/// Service dedicated to exporting and importing user-created Adhkar safely and cleanly.
class BackupService {
  /// Generate a predictable, date-stamped filename: ward_backup_YYYY-MM-DD.json
  static String generateFileName() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final suffix = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'ward_backup_$y-$m-${d}_$suffix.json';
  }

  /// Converts existing [AzkarItem] list to a [WardBackup] model.
  static WardBackup createBackupModel(List<AzkarItem> customItems) {
    final now = DateTime.now().toUtc().toIso8601String();
    final backupItems = customItems.map((item) {
      return CustomDhikrBackupModel(
        id: item.id,
        title: item.title,
        text: item.arabicText,
        repeatCount: item.targetCount > 0 ? item.targetCount : 1,
        categoryId: item.category.name,
        source: item.reference,
        note: item.reward,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();

    return WardBackup(
      createdAt: now,
      customAdhkar: backupItems,
    );
  }

  /// Exports backup to a JSON file and opens native Android share/save flow.
  static Future<bool> exportBackup(
    BuildContext context,
    List<AzkarItem> customItems,
  ) async {
    if (customItems.isEmpty) {
      AppSnackBar.showWarning(context, 'لا توجد أذكار مخصصة حالياً لتصديرها.');
      return false;
    }

    try {
      final backup = createBackupModel(customItems);
      final jsonString = backup.toFormattedJson();
      final fileName = generateFileName();

      // Write to temp file for sharing
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(jsonString, encoding: utf8, flush: true);

      // Save a copy to local documents folder as well for safe keeping
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final localCopy = File('${docsDir.path}/$fileName');
        await localCopy.writeAsString(jsonString, encoding: utf8, flush: true);
      } catch (_) {}

      final xFile = XFile(
        tempFile.path,
        mimeType: 'application/json',
        name: fileName,
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'نسخة احتياطية لأذكاري - تطبيق وِرد',
          text: 'نسخة احتياطية للأذكار المخصصة (${customItems.length} أذكار) من تطبيق وِرد.',
        ),
      );

      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'تم إنشاء النسخة الاحتياطية بنجاح');
      }
      return result.status != ShareResultStatus.unavailable;
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'تعذر تصدير النسخة الاحتياطية: $e');
      }
      return false;
    }
  }

  /// Opens the Android file picker to select a .json backup file.
  /// Validates format, parses into [WardBackup], and returns analysis against [existingItems].
  static Future<BackupAnalysisResult?> pickAndValidateBackup({
    required List<AzkarItem> existingItems,
  }) async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (files.isEmpty) {
      return null; // User cancelled
    }

    final picked = files.first;
    final bytes = await picked.readAsBytes();
    final content = utf8.decode(bytes);

    // Parses and validates schema & version
    final backup = WardBackup.fromJsonString(content);

    return analyzeBackup(backup, existingItems);
  }

  /// Normalizes Arabic text for duplicate detection (removes tashkeel and extra spaces).
  static String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // Tashkeel
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Analyzes items to detect exact ID matches and duplicate content.
  static BackupAnalysisResult analyzeBackup(
    WardBackup backup,
    List<AzkarItem> existingItems,
  ) {
    final existingIds = existingItems.map((e) => e.id).toSet();
    final existingNormTexts = existingItems.map((e) => _normalizeArabic(e.arabicText)).toSet();

    final List<CustomDhikrBackupModel> newItems = [];
    final List<CustomDhikrBackupModel> duplicateItems = [];

    for (final item in backup.customAdhkar) {
      final isIdMatch = existingIds.contains(item.id);
      final isTextMatch = existingNormTexts.contains(_normalizeArabic(item.text));

      if (isIdMatch || isTextMatch) {
        duplicateItems.add(item);
      } else {
        newItems.add(item);
      }
    }

    return BackupAnalysisResult(
      backup: backup,
      totalItems: backup.customAdhkar,
      newItems: newItems,
      duplicateItems: duplicateItems,
    );
  }

  /// Converts backup model to [AzkarItem].
  static AzkarItem toAzkarItem(CustomDhikrBackupModel model) {
    final category = AzkarCategory.values.firstWhere(
      (c) => c.name == model.categoryId,
      orElse: () => AzkarCategory.custom,
    );

    return AzkarItem(
      id: model.id.isNotEmpty
          ? model.id
          : 'custom_${DateTime.now().millisecondsSinceEpoch}_${model.title.hashCode}',
      title: model.title.isNotEmpty ? model.title : 'ذكر مخصص',
      arabicText: model.text.isNotEmpty ? model.text : model.title,
      category: category,
      categories: [category],
      targetCount: model.repeatCount > 0 ? model.repeatCount : 1,
      currentCount: 0,
      isCompleted: false,
      isCustom: true,
      reference: model.source,
      reward: model.note ?? 'ذكر خاص بك',
    );
  }

  /// Performs the actual import applying the chosen strategy (merge or replace).
  static Future<int> executeImport({
    required BuildContext context,
    required BackupAnalysisResult analysis,
    required bool replaceExisting,
  }) async {
    final repo = context.read<AzkarRepository>();
    final itemsToImport = analysis.totalItems.map(toAzkarItem).toList();

    await repo.importCustomAzkar(
      itemsToImport,
      replaceExisting: replaceExisting,
    );

    return replaceExisting ? itemsToImport.length : analysis.newItems.length;
  }
}
