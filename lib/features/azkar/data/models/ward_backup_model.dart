import 'dart:convert';

/// Represents a single custom dhikr in the extensible ward backup format.
class CustomDhikrBackupModel {
  final String id;
  final String title;
  final String text;
  final int repeatCount;
  final String? categoryId;
  final String? source;
  final String? note;
  final String createdAt;
  final String updatedAt;

  const CustomDhikrBackupModel({
    required this.id,
    required this.title,
    required this.text,
    required this.repeatCount,
    this.categoryId,
    this.source,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'text': text,
        'repeatCount': repeatCount,
        if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
        if (source != null && source!.isNotEmpty) 'source': source,
        if (note != null && note!.isNotEmpty) 'note': note,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory CustomDhikrBackupModel.fromJson(Map<String, dynamic> json) {
    return CustomDhikrBackupModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      repeatCount: (json['repeatCount'] is num)
          ? (json['repeatCount'] as num).toInt()
          : int.tryParse(json['repeatCount']?.toString() ?? '1') ?? 1,
      categoryId: json['categoryId']?.toString(),
      source: json['source']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
      updatedAt: json['updatedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }
}

/// The top-level versioned and extensible backup schema for "وِرد".
class WardBackup {
  static const String currentFormat = 'ward_backup';
  static const int currentVersion = 1;
  static const String defaultAppVersion = '2.0.0';

  final String format;
  final int version;
  final String createdAt;
  final String appVersion;
  final List<CustomDhikrBackupModel> customAdhkar;
  final Map<String, dynamic>? extraSettings;

  const WardBackup({
    this.format = currentFormat,
    this.version = currentVersion,
    required this.createdAt,
    this.appVersion = defaultAppVersion,
    required this.customAdhkar,
    this.extraSettings,
  });

  Map<String, dynamic> toJson() => {
        'format': format,
        'version': version,
        'createdAt': createdAt,
        'appVersion': appVersion,
        'data': {
          'customAdhkar': customAdhkar.map((e) => e.toJson()).toList(),
          if (extraSettings != null) 'settings': extraSettings,
        },
      };

  String toFormattedJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Parses and validates JSON string into [WardBackup], with backward compatibility
  /// for legacy backup formats.
  factory WardBackup.fromJsonString(String jsonStr) {
    if (jsonStr.trim().isEmpty) {
      throw const FormatException('الملف فارغ ولا يحتوي على بيانات.');
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (_) {
      throw const FormatException('تنسيق الملف غير صالح. يرجى اختيار ملف JSON سليم.');
    }

    if (decoded is! Map<String, dynamic>) {
      // Legacy raw list support
      if (decoded is List) {
        return WardBackup._fromLegacyList(decoded);
      }
      throw const FormatException('هيكل ملف النسخة الاحتياطية غير متوافق.');
    }

    final map = decoded;

    // Check versioned format
    final format = map['format']?.toString();
    final version = (map['version'] is num)
        ? (map['version'] as num).toInt()
        : int.tryParse(map['version']?.toString() ?? '1') ?? 1;

    // Standard version 1 schema
    if (format == currentFormat && map.containsKey('data') && map['data'] is Map) {
      final data = map['data'] as Map<String, dynamic>;
      final adhkarRaw = data['customAdhkar'];
      final List<CustomDhikrBackupModel> list = [];

      if (adhkarRaw is List) {
        for (final item in adhkarRaw) {
          if (item is Map<String, dynamic>) {
            final parsed = CustomDhikrBackupModel.fromJson(item);
            if (parsed.text.trim().isNotEmpty || parsed.title.trim().isNotEmpty) {
              list.add(parsed);
            }
          }
        }
      }

      return WardBackup(
        format: format ?? currentFormat,
        version: version,
        createdAt: map['createdAt']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
        appVersion: map['appVersion']?.toString() ?? defaultAppVersion,
        customAdhkar: list,
        extraSettings: data['settings'] is Map<String, dynamic>
            ? data['settings'] as Map<String, dynamic>
            : null,
      );
    }

    // Legacy format handling: customAzkar / azkar / items directly at root
    List<dynamic>? rawList;
    if (map['customAzkar'] is List) {
      rawList = map['customAzkar'] as List;
    } else if (map['azkar'] is List) {
      rawList = map['azkar'] as List;
    } else if (map['items'] is List) {
      rawList = map['items'] as List;
    }

    if (rawList != null) {
      return WardBackup._fromLegacyList(rawList);
    }

    throw const FormatException('الملف المحدد لا يطابق صيغة النسخ الاحتياطي لتطبيق وِرد.');
  }

  factory WardBackup._fromLegacyList(List<dynamic> list) {
    final now = DateTime.now().toUtc().toIso8601String();
    final parsedList = <CustomDhikrBackupModel>[];

    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final title = map['title']?.toString() ?? 'ذكر مخصص';
        final text = map['arabicText']?.toString() ?? map['text']?.toString() ?? title;
        final targetCount = (map['targetCount'] is num)
            ? (map['targetCount'] as num).toInt()
            : (map['repeatCount'] is num)
                ? (map['repeatCount'] as num).toInt()
                : 1;

        parsedList.add(CustomDhikrBackupModel(
          id: map['id']?.toString() ?? 'legacy_${DateTime.now().millisecondsSinceEpoch}_$i',
          title: title,
          text: text,
          repeatCount: targetCount > 0 ? targetCount : 1,
          source: map['reference']?.toString() ?? map['source']?.toString(),
          note: map['reward']?.toString() ?? map['note']?.toString(),
          createdAt: now,
          updatedAt: now,
        ));
      }
    }

    return WardBackup(
      createdAt: now,
      customAdhkar: parsedList,
    );
  }
}
