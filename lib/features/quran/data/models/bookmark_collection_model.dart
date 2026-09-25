import 'package:equatable/equatable.dart';

/// Bookmark Collection model (e.g. Favorite Ayat, Patience, Dua Ayat, Memorization)
class BookmarkCollectionModel extends Equatable {
  final String id;
  final String? userId;
  final String name;
  final String color; // Hex string e.g. '#D4AF37'
  final DateTime createdAt;
  final DateTime updatedAt;

  const BookmarkCollectionModel({
    required this.id,
    this.userId,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookmarkCollectionModel.fromJson(Map<String, dynamic> json) {
    return BookmarkCollectionModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#D4AF37',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'userId': userId,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookmarkCollectionModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookmarkCollectionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, color, createdAt, updatedAt];
}
