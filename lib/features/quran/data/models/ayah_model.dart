import 'package:equatable/equatable.dart';

class AyahModel extends Equatable {
  final int id;
  final String text;
  final int juz;
  final int page;
  final bool sajda;

  const AyahModel({
    required this.id,
    required this.text,
    required this.juz,
    required this.page,
    this.sajda = false,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      id: json['id'] as int,
      text: json['text'] as String,
      juz: json['juz'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
      sajda: json['sajda'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'juz': juz,
      'page': page,
      if (sajda) 'sajda': true,
    };
  }

  @override
  List<Object?> get props => [id, text, juz, page, sajda];
}
