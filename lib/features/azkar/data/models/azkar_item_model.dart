import 'package:equatable/equatable.dart';

enum AzkarCategory {
  morning,
  evening,
  postPrayer,
  sleep,
  qiyam,
  supplications,
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
        return 'النوم والاستيقاظ';
      case AzkarCategory.qiyam:
        return 'قيام الليل';
      case AzkarCategory.supplications:
        return 'مفاتيح وأوقات الإجابة';
      case AzkarCategory.general:
        return 'أذكار عامة وتسبيح';
      case AzkarCategory.custom:
        return 'أذكاري المخصصة';
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
        return 'قبل النوم وليلاً وعند الاستيقاظ';
      case AzkarCategory.qiyam:
        return 'في الثلث الأخير من الليل قبل الفجر';
      case AzkarCategory.supplications:
        return 'أوقات وأدعية مستجابة لا تُرد بإذن الله';
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
  final List<AzkarCategory> categories;
  final String title;
  final String arabicText;
  final String? reference; // المصدر مثل صحيح مسلم، سنن أبي داود
  final String? reward; // الفضل والثواب
  final int targetCount; // عدد المرات المطلوب (1، 3، 33، 100...)
  final int currentCount; // عدد المرات المنجزة اليوم
  final bool isCompleted;
  final bool isCustom;

  const AzkarItem({
    required this.id,
    required this.category,
    List<AzkarCategory>? categories,
    required this.title,
    required this.arabicText,
    this.reference,
    this.reward,
    required this.targetCount,
    this.currentCount = 0,
    this.isCompleted = false,
    this.isCustom = false,
  }) : categories = categories ?? const [];

  List<AzkarCategory> get effectiveCategories =>
      categories.isNotEmpty ? categories : [category];

  bool matchesCategory(AzkarCategory cat) {
    if (cat == AzkarCategory.custom) {
      return isCustom || category == AzkarCategory.custom || effectiveCategories.contains(AzkarCategory.custom);
    }
    return effectiveCategories.contains(cat) || category == cat;
  }

  AzkarItem copyWith({
    String? id,
    AzkarCategory? category,
    List<AzkarCategory>? categories,
    String? title,
    String? arabicText,
    String? reference,
    String? reward,
    int? targetCount,
    int? currentCount,
    bool? isCompleted,
    bool? isCustom,
  }) {
    final newCat = category ?? this.category;
    final newCats = categories ?? (this.categories.isNotEmpty ? this.categories : [newCat]);
    final normalizedCats = newCats.contains(newCat) ? newCats : [newCat, ...newCats];

    return AzkarItem(
      id: id ?? this.id,
      category: newCat,
      categories: normalizedCats,
      title: title ?? this.title,
      arabicText: arabicText ?? this.arabicText,
      reference: reference ?? this.reference,
      reward: reward ?? this.reward,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      isCompleted: isCompleted ?? this.isCompleted,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.name,
      'categories': effectiveCategories.map((c) => c.name).toList(),
      'title': title,
      'arabicText': arabicText,
      'reference': reference,
      'reward': reward,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'isCompleted': isCompleted,
      'isCustom': isCustom,
    };
  }

  factory AzkarItem.fromJson(Map<String, dynamic> json) {
    final primaryCategory = AzkarCategory.values.firstWhere(
      (c) => c.name == json['category'],
      orElse: () => AzkarCategory.general,
    );

    List<AzkarCategory> parsedCategories = [];
    if (json['categories'] is List) {
      parsedCategories = (json['categories'] as List)
          .map((c) => AzkarCategory.values.firstWhere(
                (v) => v.name == c,
                orElse: () => AzkarCategory.general,
              ))
          .toSet()
          .toList();
    }
    if (parsedCategories.isEmpty) {
      parsedCategories = [primaryCategory];
    } else if (!parsedCategories.contains(primaryCategory)) {
      parsedCategories.insert(0, primaryCategory);
    }

    return AzkarItem(
      id: json['id'] as String,
      category: primaryCategory,
      categories: parsedCategories,
      title: json['title'] as String? ?? '',
      arabicText: json['arabicText'] as String,
      reference: json['reference'] as String?,
      reward: json['reward'] as String?,
      targetCount: json['targetCount'] as int? ?? 1,
      currentCount: json['currentCount'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        category,
        categories,
        title,
        arabicText,
        reference,
        reward,
        targetCount,
        currentCount,
        isCompleted,
        isCustom,
      ];
}
