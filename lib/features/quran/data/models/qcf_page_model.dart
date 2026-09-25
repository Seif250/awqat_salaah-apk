import 'package:equatable/equatable.dart';

/// Represents a single word/glyph unit in the QCF V2 layout.
class QcfWordModel extends Equatable {
  final String location; // e.g. "2:1:1" (surah:ayah:wordIndex)
  final String word; // Uthmani text representation
  final String qpcV2; // Exact QCF V2 font ligature glyph(s)
  final String? qpcV1;

  const QcfWordModel({
    required this.location,
    required this.word,
    required this.qpcV2,
    this.qpcV1,
  });

  factory QcfWordModel.fromJson(Map<String, dynamic> json) {
    return QcfWordModel(
      location: json['location'] as String? ?? '',
      word: json['word'] as String? ?? '',
      qpcV2: json['qpcV2'] as String? ?? '',
      qpcV1: json['qpcV1'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'location': location,
        'word': word,
        'qpcV2': qpcV2,
        if (qpcV1 != null) 'qpcV1': qpcV1,
      };

  int? get surahId {
    final parts = location.split(':');
    return parts.isNotEmpty ? int.tryParse(parts[0]) : null;
  }

  int? get ayahId {
    final parts = location.split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) : null;
  }

  int? get wordIndex {
    final parts = location.split(':');
    return parts.length > 2 ? int.tryParse(parts[2]) : null;
  }

  String get ayahKey => '${surahId ?? 0}:${ayahId ?? 0}';

  bool get isAyahEnd => word.contains(RegExp(r'[٠-٩0-9]'));

  @override
  List<Object?> get props => [location, word, qpcV2, qpcV1];
}

/// Represents one of the 15 fixed lines on a standard Mushaf page.
class QcfLineModel extends Equatable {
  final int line; // 1..15
  final String type; // 'surah-header' | 'basmala' | 'text'
  final String? text; // Readable Arabic text
  final String? surah; // 3-digit Surah number, e.g. "002"
  final String? verseRange; // e.g. "2:1-2:2"
  final String? qpcV2; // For basmala lines or single ligature blocks
  final String? qpcV1;
  final List<QcfWordModel> words;

  const QcfLineModel({
    required this.line,
    required this.type,
    this.text,
    this.surah,
    this.verseRange,
    this.qpcV2,
    this.qpcV1,
    this.words = const [],
  });

  factory QcfLineModel.fromJson(Map<String, dynamic> json) {
    final wordsRaw = json['words'] as List<dynamic>? ?? [];
    return QcfLineModel(
      line: json['line'] as int? ?? 1,
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String?,
      surah: json['surah'] as String?,
      verseRange: json['verseRange'] as String?,
      qpcV2: json['qpcV2'] as String?,
      qpcV1: json['qpcV1'] as String?,
      words: wordsRaw
          .map((w) => QcfWordModel.fromJson(w as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'line': line,
        'type': type,
        if (text != null) 'text': text,
        if (surah != null) 'surah': surah,
        if (verseRange != null) 'verseRange': verseRange,
        if (qpcV2 != null) 'qpcV2': qpcV2,
        if (qpcV1 != null) 'qpcV1': qpcV1,
        if (words.isNotEmpty) 'words': words.map((w) => w.toJson()).toList(),
      };

  bool get isSurahHeader => type == 'surah-header';
  bool get isBasmala => type == 'basmala';
  bool get isText => type == 'text';

  int? get surahId => surah != null ? int.tryParse(surah!) : null;

  @override
  List<Object?> get props => [
        line,
        type,
        text,
        surah,
        verseRange,
        qpcV2,
        qpcV1,
        words,
      ];
}

/// Represents an authentic Madinah Mushaf page (1..604)
/// with its deterministic line composition.
class QcfPageModel extends Equatable {
  final int page;
  final List<QcfLineModel> lines;

  const QcfPageModel({
    required this.page,
    required this.lines,
  });

  factory QcfPageModel.fromJson(Map<String, dynamic> json) {
    final linesRaw = json['lines'] as List<dynamic>? ?? [];
    return QcfPageModel(
      page: json['page'] as int? ?? 1,
      lines: linesRaw
          .map((l) => QcfLineModel.fromJson(l as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'page': page,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  /// Returns all unique ayah keys ("surahId:ayahId") appearing on this page.
  List<String> get uniqueAyahKeys {
    final keys = <String>{};
    for (final l in lines) {
      for (final w in l.words) {
        if (w.surahId != null && w.ayahId != null) {
          keys.add(w.ayahKey);
        }
      }
    }
    return keys.toList(growable: false);
  }

  /// Returns the primary surah ID for the header/footer of this page.
  int get primarySurahId {
    for (final l in lines) {
      if (l.surahId != null) return l.surahId!;
      for (final w in l.words) {
        if (w.surahId != null) return w.surahId!;
      }
    }
    return 1;
  }

  @override
  List<Object?> get props => [page, lines];
}
