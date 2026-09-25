import 'package:equatable/equatable.dart';

class LastReadModel extends Equatable {
  final int surahId;
  final String surahName;
  final int ayahId;
  final int page;
  final DateTime timestamp;

  const LastReadModel({
    required this.surahId,
    required this.surahName,
    required this.ayahId,
    required this.page,
    required this.timestamp,
  });

  factory LastReadModel.fromJson(Map<String, dynamic> json) {
    return LastReadModel(
      surahId: json['surahId'] as int,
      surahName: json['surahName'] as String,
      ayahId: json['ayahId'] as int,
      page: json['page'] as int? ?? 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahId': surahId,
      'surahName': surahName,
      'ayahId': ayahId,
      'page': page,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [surahId, surahName, ayahId, page, timestamp];
}
