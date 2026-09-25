import 'package:equatable/equatable.dart';
import 'ayah_model.dart';

class SurahModel extends Equatable {
  final int id;
  final String name;
  final String type; // مكية / مدنية
  final int totalVerses;
  final int startPage;
  final int juz;
  final List<AyahModel> verses;

  const SurahModel({
    required this.id,
    required this.name,
    required this.type,
    required this.totalVerses,
    required this.startPage,
    required this.juz,
    this.verses = const [],
  });

  bool get isMeccan => type.contains('مكية');

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final rawVerses = json['verses'] as List<dynamic>? ?? [];
    return SurahModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'مكية',
      totalVerses: json['total_verses'] as int? ?? rawVerses.length,
      startPage: json['start_page'] as int? ?? 1,
      juz: json['juz'] as int? ?? 1,
      verses: rawVerses
          .map((v) => AyahModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'total_verses': totalVerses,
      'start_page': startPage,
      'juz': juz,
      if (verses.isNotEmpty)
        'verses': verses.map((v) => v.toJson()).toList(),
    };
  }

  SurahModel copyWith({
    int? id,
    String? name,
    String? type,
    int? totalVerses,
    int? startPage,
    int? juz,
    List<AyahModel>? verses,
  }) {
    return SurahModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      totalVerses: totalVerses ?? this.totalVerses,
      startPage: startPage ?? this.startPage,
      juz: juz ?? this.juz,
      verses: verses ?? this.verses,
    );
  }

  @override
  List<Object?> get props => [id, name, type, totalVerses, startPage, juz, verses];
}
