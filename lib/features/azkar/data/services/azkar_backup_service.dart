import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../presentation/bloc/azkar_bloc.dart';
import '../../presentation/bloc/azkar_event.dart';
import '../models/azkar_item_model.dart';
import '../repositories/azkar_repository.dart';

/// Service responsible for exporting and importing custom Azkar backups in JSON format,
/// managing backup storage directories, and providing streamlined 1-click backup/restore.
class AzkarBackupService {
  static const String appIdentifier = 'awqat_salaah';
  static const String backupType = 'custom_azkar_backup';
  static const int currentBackupVersion = 1;
  static const String prefBackupDirKey = 'pref_azkar_backup_directory';

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

  /// Gets the user's custom backup folder from preferences, if set and valid.
  static Future<String?> getSavedBackupDirectory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(prefBackupDirKey);
      if (path != null && path.trim().isNotEmpty) {
        final dir = Directory(path.trim());
        if (await dir.exists()) {
          return dir.path;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Saves the user's preferred backup directory.
  static Future<void> setSavedBackupDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefBackupDirKey, path.trim());
  }

  /// Clears the saved backup directory and reverts to default.
  static Future<void> resetSavedBackupDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefBackupDirKey);
  }

  /// Determines the best default backup directory based on OS.
  static Future<String> getDefaultBackupDirectory() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      try {
        if (await downloadDir.exists()) {
          return downloadDir.path;
        }
      } catch (_) {}
    }

    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null && await downloads.exists()) {
        return downloads.path;
      }
    } catch (_) {}

    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        return ext.path;
      }
    } catch (_) {}

    final docs = await getApplicationDocumentsDirectory();
    return docs.path;
  }

  /// Opens the directory picker so the user can choose a storage folder.
  /// If selected, saves it to preferences and returns the path.
  static Future<String?> pickBackupDirectory() async {
    final selected = await FilePicker.getDirectoryPath(
      dialogTitle: 'اختر مجلد حفظ النسخ الاحتياطية للأذكار',
    );
    if (selected != null && selected.trim().isNotEmpty) {
      await setSavedBackupDirectory(selected.trim());
      return selected.trim();
    }
    return null;
  }


  /// Exports custom Azkar items directly to a .json file in the user's configured
  /// directory (or default directory), with robust fallbacks.
  /// Returns the absolute path of the created file.
  static Future<String> exportBackupToFile(
    List<AzkarItem> customItems, {
    String? customDirectory,
  }) async {
    final jsonContent = generateBackupJson(customItems);
    final fileName = defaultFileName();

    // 1. Target directory
    String targetDirPath = customDirectory ??
        await getSavedBackupDirectory() ??
        await getDefaultBackupDirectory();

    try {
      final dir = Directory(targetDirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonContent, encoding: utf8, flush: true);
      return file.path;
    } catch (e) {
      // Fallback 1: external app storage directory
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          final fallbackFile = File('${ext.path}/$fileName');
          await fallbackFile.writeAsString(jsonContent, encoding: utf8, flush: true);
          return fallbackFile.path;
        }
      } catch (_) {}

      // Fallback 2: documents directory
      final docs = await getApplicationDocumentsDirectory();
      final fallbackFile = File('${docs.path}/$fileName');
      await fallbackFile.writeAsString(jsonContent, encoding: utf8, flush: true);
      return fallbackFile.path;
    }
  }

  /// Alias for backward compatibility with [exportBackupToFile]
  static Future<String?> saveBackupToStorage(List<AzkarItem> customItems) async {
    try {
      return await exportBackupToFile(customItems);
    } catch (_) {
      return null;
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
        subject: 'نسخة احتياطية للأذكار المخصصة - تطبيق وِرد',
        text: 'نسخة احتياطية لأذكاري المخصصة (${customItems.length} أذكار) من تطبيق وِرد.',
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

  /// Executes the direct backup flow:
  /// 1. Retrieves custom items from repository.
  /// 2. If empty, alerts the user.
  /// 3. Directly writes JSON to storage folder.
  /// 4. Shows clean confirmation modal with full path & share button.
  static Future<void> performBackupFlow(
    BuildContext context, {
    List<AzkarItem>? customItems,
  }) async {
    final repo = context.read<AzkarRepository>();
    final items = customItems ?? repo.getCustomAzkarItems();

    if (items.isEmpty) {
      AppSnackBar.showWarning(context, 'لا توجد أذكار مخصصة حالياً لحفظها. أضف أذكاراً أولاً!');
      return;
    }

    try {
      final filePath = await exportBackupToFile(items);
      if (!context.mounted) return;

      _showBackupSavedDialog(
        context: context,
        filePath: filePath,
        count: items.length,
        items: items,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(context, 'حدث خطأ أثناء حفظ النسخة الاحتياطية: $e');
    }
  }

  /// Executes the direct restore flow:
  /// 1. Opens file picker for .json.
  /// 2. Parses and verifies items.
  /// 3. Imports into AzkarBloc immediately.
  /// 4. Shows clean SnackBar notification with count.
  static Future<void> performRestoreFlow(BuildContext context) async {
    try {
      final items = await pickAndImportFile();
      if (items == null) {
        return; // User cancelled
      }
      if (items.isEmpty) {
        if (!context.mounted) return;
        AppSnackBar.showWarning(context, 'الملف المحدد لا يحتوي على أذكار صالحة.');
        return;
      }

      if (!context.mounted) return;

      // Dispatch import event to AzkarBloc
      context.read<AzkarBloc>().add(
            ImportCustomAzkarEvent(items: items, replaceExisting: false),
          );

      AppSnackBar.showSuccess(context, 'تمت استعادة ${items.length} أذكار مخصصة بنجاح!');
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(context, 'تعذر استرجاع الملف: $e');
    }
  }

  /// Clean dialog displaying exact saved file location with copy & share actions.
  static void _showBackupSavedDialog({
    required BuildContext context,
    required String filePath,
    required int count,
    required List<AzkarItem> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم حفظ النسخة الاحتياطية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم حفظ أذكارك المخصصة ($count أذكار) كملف JSON بنجاح في المسار التالي:',
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 20, color: AppColors.accentGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      filePath,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'نسخ المسار',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: filePath));
                      AppSnackBar.showInfo(context, 'تم نسخ مسار الملف إلى الحافظة');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('مشاركة الملف'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentGold,
              side: const BorderSide(color: AppColors.accentGold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dlgCtx);
              shareBackupFile(items);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}

