import 'package:equatable/equatable.dart';

enum AzkarCategory {
  morning,
  evening,
  postPrayer,
  sleep,
  qiyam,
  general,
  custom,
}

extension AzkarCategoryExtension on AzkarCategory {
  String get titleArabic {
    switch (this) {
      case AzkarCategory.morning:
        return 'أذكار الصباح';
      case AzkarCategory.evening:
        return 'أذكار المساء';
      case AzkarCategory.postPrayer:
        return 'بعد الصلاة';
      case AzkarCategory.sleep:
        return 'أذكار النوم';
      case AzkarCategory.qiyam:
        return 'قيام الليل';
      case AzkarCategory.general:
        return 'أذكار عامة وتسبيح';
      case AzkarCategory.custom:
        return 'أذكاري المخصصة';
    }
  }

  String get iconAssetOrEmoji {
    switch (this) {
      case AzkarCategory.morning:
        return '☀️';
      case AzkarCategory.evening:
        return '🌙';
      case AzkarCategory.postPrayer:
        return '🕌';
      case AzkarCategory.sleep:
        return '🛏️';
      case AzkarCategory.qiyam:
        return '🌌';
      case AzkarCategory.general:
        return '📿';
      case AzkarCategory.custom:
        return '⭐';
    }
  }

  String get timeDescription {
    switch (this) {
      case AzkarCategory.morning:
        return 'من بعد صلاة الفجر حتى الظهر';
      case AzkarCategory.evening:
        return 'من بعد صلاة العصر والمغرب حتى العشاء';
      case AzkarCategory.postPrayer:
        return 'دبر كل صلاة مكتوبة';
      case AzkarCategory.sleep:
        return 'قبل النوم ليلاً';
      case AzkarCategory.qiyam:
        return 'في الثلث الأخير من الليل قبل الفجر';
      case AzkarCategory.general:
        return 'طوال اليوم في كل وقت';
      case AzkarCategory.custom:
        return 'أذكار وأوراد مخصصة منك';
    }
  }
}

class AzkarItem extends Equatable {
  final String id;
  final AzkarCategory category;
  final String title;
  final String arabicText;
  final String? reference; // المصدر مثل صحيح مسلم، سنن أبي داود
  final String? reward; // الفضل والثواب
  final int targetCount; // عدد المرات المطلوب (1، 3، 33، 100...)
  final int currentCount; // عدد المرات المنجزة اليوم
  final bool isCompleted;

  const AzkarItem({
    required this.id,
    required this.category,
    required this.title,
    required this.arabicText,
    this.reference,
    this.reward,
    required this.targetCount,
    this.currentCount = 0,
    this.isCompleted = false,
  });

  AzkarItem copyWith({
    String? id,
    AzkarCategory? category,
    String? title,
    String? arabicText,
    String? reference,
    String? reward,
    int? targetCount,
    int? currentCount,
    bool? isCompleted,
  }) {
    return AzkarItem(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      arabicText: arabicText ?? this.arabicText,
      reference: reference ?? this.reference,
      reward: reward ?? this.reward,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'title': title,
      'arabicText': arabicText,
      'reference': reference,
      'reward': reward,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'isCompleted': isCompleted,
    };
  }

  factory AzkarItem.fromJson(Map<String, dynamic> json) {
    return AzkarItem(
      id: json['id'] as String,
      category: AzkarCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AzkarCategory.general,
      ),
      title: json['title'] as String? ?? '',
      arabicText: json['arabicText'] as String,
      reference: json['reference'] as String?,
      reward: json['reward'] as String?,
      targetCount: json['targetCount'] as int? ?? 1,
      currentCount: json['currentCount'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        category,
        title,
        arabicText,
        reference,
        reward,
        targetCount,
        currentCount,
        isCompleted,
      ];
}
