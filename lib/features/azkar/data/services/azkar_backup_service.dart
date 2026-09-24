import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/azkar_item_model.dart';

/// Service responsible for exporting and importing custom Azkar backups in JSON format.
class AzkarBackupService {
  static const String appIdentifier = 'awqat_salaah';
  static const String backupType = 'custom_azkar_backup';
  static const int currentBackupVersion = 1;

  /// Generates formatted, human-readable JSON string representing the custom Azkar backup.
  static String generateBackupJson(List<AzkarItem> customItems) {
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'app': appIdentifier,
      'type': backupType,
      'version': currentBackupVersion,
      'exportedAt': now,
      'count': customItems.length,
      'customAzkar': customItems.map((item) => item.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Parses and validates JSON backup content.
  /// Supports both standard wrapped format and raw list format for maximum resilience.
  static List<AzkarItem> parseBackupJson(String jsonString) {
    if (jsonString.trim().isEmpty) {
      throw const FormatException('محتوى الملف فارغ');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } catch (e) {
      throw const FormatException('تنسيق ملف JSON غير صالح');
    }

    List<dynamic> rawList = [];

    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('customAzkar') && decoded['customAzkar'] is List) {
        rawList = decoded['customAzkar'] as List<dynamic>;
      } else if (decoded.containsKey('azkar') && decoded['azkar'] is List) {
        rawList = decoded['azkar'] as List<dynamic>;
      } else if (decoded.containsKey('items') && decoded['items'] is List) {
        rawList = decoded['items'] as List<dynamic>;
      } else {
        throw const FormatException('الملف لا يحتوي على قائمة أذكار صالحة');
      }
    } else if (decoded is List) {
      rawList = decoded;
    } else {
      throw const FormatException('صيغة البيانات غير مدعومة');
    }

    if (rawList.isEmpty) {
      return [];
    }

    final List<AzkarItem> result = [];

    for (var i = 0; i < rawList.length; i++) {
      final entry = rawList[i];
      if (entry is! Map) continue;

      try {
        final map = Map<String, dynamic>.from(entry);
        final title = map['title']?.toString() ?? 'ذكر مخصص';
        final arabicText = map['arabicText']?.toString() ?? '';

        if (arabicText.trim().isEmpty && title.trim().isEmpty) {
          continue; // skip invalid empty entry
        }

        final id = map['id']?.toString() ??
            'imported_${DateTime.now().millisecondsSinceEpoch}_$i';

        final targetCount = (map['targetCount'] is num)
            ? (map['targetCount'] as num).toInt()
            : int.tryParse(map['targetCount']?.toString() ?? '1') ?? 1;

        result.add(AzkarItem(
          id: id,
          category: AzkarCategory.custom,
          title: title,
          arabicText: arabicText.isNotEmpty ? arabicText : title,
          reference: map['reference']?.toString(),
          reward: map['reward']?.toString() ?? 'ذكر خاص بك',
          targetCount: targetCount > 0 ? targetCount : 1,
          currentCount: 0,
          isCompleted: false,
          isCustom: true,
        ));
      } catch (_) {
        // Skip individual malformed item
      }
    }

    return result;
  }

  /// Default backup filename with formatted timestamp.
  static String defaultFileName() {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return 'awqat_salaah_azkar_backup_$y$m${d}_$h$min.json';
  }

  /// Saves backup to file by letting the user choose location (Internal/External storage/Downloads).
  /// Returns saved file path or message on success, or null if cancelled.
  static Future<String?> saveBackupToStorage(List<AzkarItem> customItems) async {
    final jsonContent = generateBackupJson(customItems);
    final bytes = Uint8List.fromList(utf8.encode(jsonContent));
    final fileName = defaultFileName();

    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'حفظ النسخة الاحتياطية للأذكار المخصصة',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (savedUri == null) {
        return null; // User cancelled
      }

      // If a file URI was returned and file is empty or not yet written:
      if (savedUri.isScheme('file') && savedUri.toFilePath().isNotEmpty) {
        try {
          final file = File(savedUri.toFilePath());
          if (!await file.exists() || (await file.length()) == 0) {
            await file.writeAsBytes(bytes, flush: true);
          }
        } catch (_) {}
      }

      return savedUri.path;
    } catch (e) {
      // Fallback: write to app documents directory
      final docsDir = await getApplicationDocumentsDirectory();
      final fallbackFile = File('${docsDir.path}/$fileName');
      await fallbackFile.writeAsBytes(bytes, flush: true);
      return fallbackFile.path;
    }
  }

  /// Shares backup file via native share sheet (Google Drive, WhatsApp, Telegram, Files, etc.).
  static Future<bool> shareBackupFile(List<AzkarItem> customItems) async {
    final jsonContent = generateBackupJson(customItems);
    final fileName = defaultFileName();

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsString(jsonContent, encoding: utf8, flush: true);

    final xFile = XFile(
      tempFile.path,
      mimeType: 'application/json',
      name: fileName,
    );

    final shareResult = await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: 'نسخة احتياطية للأذكار المخصصة - تطبيق أوقات الصلاة',
        text: 'نسخة احتياطية لأذكاري المخصصة (${customItems.length} أذكار) من تطبيق أوقات الصلاة.',
      ),
    );

    return shareResult.status != ShareResultStatus.unavailable;
  }

  /// Opens file picker to select a JSON backup file and parses its contents.
  static Future<List<AzkarItem>?> pickAndImportFile() async {
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

    if (content.trim().isEmpty) {
      throw const FormatException('الملف المحدد فارغ');
    }

    return parseBackupJson(content);
  }
}
