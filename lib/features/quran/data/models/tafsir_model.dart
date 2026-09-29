import 'package:equatable/equatable.dart';

/// Represents a Tafsir book or scholarly resource.
class TafsirResource extends Equatable {
  final int id;
  final String name;
  final String authorName;
  final String language;
  final String? slug;

  const TafsirResource({
    required this.id,
    required this.name,
    required this.authorName,
    required this.language,
    this.slug,
  });

  factory TafsirResource.fromJson(Map<String, dynamic> json) {
    String resName = json['name'] as String? ?? '';
    final translatedName = json['translated_name'];
    if (translatedName is Map && translatedName['name'] != null) {
      final tName = translatedName['name'] as String;
      if (tName.trim().isNotEmpty) {
        resName = tName;
      }
    }

    return TafsirResource(
      id: json['id'] as int? ?? 0,
      name: resName,
      authorName: json['author_name'] as String? ?? '',
      language: json['language_name'] as String? ?? 'arabic',
      slug: json['slug'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'author_name': authorName,
        'language_name': language,
        if (slug != null) 'slug': slug,
      };

  @override
  List<Object?> get props => [id, name, authorName, language, slug];
}

/// Represents the Tafsir content for a specific Ayah.
class Tafsir extends Equatable {
  final String verseKey; // e.g. "2:255"
  final int resourceId;
  final String resourceName;
  final String text;

  const Tafsir({
    required this.verseKey,
    required this.resourceId,
    required this.resourceName,
    required this.text,
  });

  factory Tafsir.fromJson(Map<String, dynamic> json, {String? defaultVerseKey}) {
    String vKey = defaultVerseKey ?? '';
    final verses = json['verses'];
    if (verses is Map && verses.isNotEmpty) {
      vKey = verses.keys.first.toString();
    }

    String rName = json['resource_name'] as String? ?? '';
    final translatedName = json['translated_name'];
    if (translatedName is Map && translatedName['name'] != null) {
      rName = translatedName['name'] as String;
    }

    return Tafsir(
      verseKey: vKey,
      resourceId: json['resource_id'] as int? ?? 0,
      resourceName: rName,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'verseKey': verseKey,
        'resource_id': resourceId,
        'resource_name': resourceName,
        'text': text,
      };

  @override
  List<Object?> get props => [verseKey, resourceId, resourceName, text];
}
