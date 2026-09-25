import 'package:equatable/equatable.dart';

/// Full Ayah Bookmark model with color, note, page, and collection links
class BookmarkModel extends Equatable {
  final String id;
  final String? userId;
  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final int pageNumber;
  final String color; // Hex color string, e.g. '#D4AF37'
  final String? note;
  final List<String> collectionIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookmarkModel({
    required this.id,
    this.userId,
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.pageNumber,
    this.color = '#D4AF37', // Default warm gold
    this.note,
    this.collectionIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique key matching Surah:Ayah for quick lookups
  String get ayahKey => '$surahId:$ayahNumber';

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    final rawCollections = json['collectionIds'] as List<dynamic>?;
    return BookmarkModel(
      id: json['id'] as String? ?? '${json['surahId']}:${json['ayahNumber'] ?? json['ayahId']}',
      userId: json['userId'] as String?,
      ayahId: (json['ayahId'] as num?)?.toInt() ?? 1,
      surahId: (json['surahId'] as num?)?.toInt() ?? 1,
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? (json['ayahId'] as num?)?.toInt() ?? 1,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      color: json['color'] as String? ?? '#D4AF37',
      note: json['note'] as String?,
      collectionIds: rawCollections != null
          ? rawCollections.map((e) => e.toString()).toList()
          : const [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      'ayahId': ayahId,
      'surahId': surahId,
      'ayahNumber': ayahNumber,
      'pageNumber': pageNumber,
      'color': color,
      if (note != null) 'note': note,
      'collectionIds': collectionIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookmarkModel copyWith({
    String? id,
    String? userId,
    int? ayahId,
    int? surahId,
    int? ayahNumber,
    int? pageNumber,
    String? color,
    String? note,
    List<String>? collectionIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ayahId: ayahId ?? this.ayahId,
      surahId: surahId ?? this.surahId,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      pageNumber: pageNumber ?? this.pageNumber,
      color: color ?? this.color,
      note: note ?? this.note,
      collectionIds: collectionIds ?? this.collectionIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        ayahId,
        surahId,
        ayahNumber,
        pageNumber,
        color,
        note,
        collectionIds,
        createdAt,
        updatedAt,
      ];
}
