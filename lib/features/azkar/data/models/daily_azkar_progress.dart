import 'package:equatable/equatable.dart';

class DailyAzkarProgress extends Equatable {
  final String date; // YYYY-MM-DD
  final Map<String, int> itemCounts; // itemId -> count today
  final Set<String> completedItemIds; // items marked done today
  final int freeTasbihCount; // عداد المسبحة الحرة اليومي
  final int totalLifetimeTasbih; // إجمالي التسبيحات مدى الحياة

  const DailyAzkarProgress({
    required this.date,
    this.itemCounts = const {},
    this.completedItemIds = const {},
    this.freeTasbihCount = 0,
    this.totalLifetimeTasbih = 0,
  });

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool get isToday => date == todayKey();

  DailyAzkarProgress copyWith({
    String? date,
    Map<String, int>? itemCounts,
    Set<String>? completedItemIds,
    int? freeTasbihCount,
    int? totalLifetimeTasbih,
  }) {
    return DailyAzkarProgress(
      date: date ?? this.date,
      itemCounts: itemCounts ?? this.itemCounts,
      completedItemIds: completedItemIds ?? this.completedItemIds,
      freeTasbihCount: freeTasbihCount ?? this.freeTasbihCount,
      totalLifetimeTasbih: totalLifetimeTasbih ?? this.totalLifetimeTasbih,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'itemCounts': itemCounts,
      'completedItemIds': completedItemIds.toList(),
      'freeTasbihCount': freeTasbihCount,
      'totalLifetimeTasbih': totalLifetimeTasbih,
    };
  }

  factory DailyAzkarProgress.fromJson(Map<String, dynamic> json) {
    return DailyAzkarProgress(
      date: json['date'] as String? ?? todayKey(),
      itemCounts: (json['itemCounts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      completedItemIds: (json['completedItemIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      freeTasbihCount: json['freeTasbihCount'] as int? ?? 0,
      totalLifetimeTasbih: json['totalLifetimeTasbih'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        date,
        itemCounts,
        completedItemIds,
        freeTasbihCount,
        totalLifetimeTasbih,
      ];
}
