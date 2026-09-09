import 'package:equatable/equatable.dart';

class CustomZikr extends Equatable {
  final String id;
  final String title;
  final String arabicText;
  final int targetCount;
  final int? reminderHour; // 0-23
  final int? reminderMinute; // 0-59
  final bool isReminderEnabled;
  final DateTime createdAt;

  const CustomZikr({
    required this.id,
    required this.title,
    required this.arabicText,
    this.targetCount = 33,
    this.reminderHour,
    this.reminderMinute,
    this.isReminderEnabled = false,
    required this.createdAt,
  });

  CustomZikr copyWith({
    String? id,
    String? title,
    String? arabicText,
    int? targetCount,
    int? reminderHour,
    int? reminderMinute,
    bool? isReminderEnabled,
    DateTime? createdAt,
  }) {
    return CustomZikr(
      id: id ?? this.id,
      title: title ?? this.title,
      arabicText: arabicText ?? this.arabicText,
      targetCount: targetCount ?? this.targetCount,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'arabicText': arabicText,
      'targetCount': targetCount,
      'reminderHour': reminderHour,
      'reminderMinute': reminderMinute,
      'isReminderEnabled': isReminderEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomZikr.fromJson(Map<String, dynamic> json) {
    return CustomZikr(
      id: json['id'] as String,
      title: json['title'] as String,
      arabicText: json['arabicText'] as String,
      targetCount: json['targetCount'] as int? ?? 33,
      reminderHour: json['reminderHour'] as int?,
      reminderMinute: json['reminderMinute'] as int?,
      isReminderEnabled: json['isReminderEnabled'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        arabicText,
        targetCount,
        reminderHour,
        reminderMinute,
        isReminderEnabled,
        createdAt,
      ];
}
