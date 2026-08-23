import 'package:equatable/equatable.dart';
import '../../../../core/constants/prayer_constants.dart';

class PrayerTimeModel extends Equatable {
  final PrayerType type;
  final DateTime time;
  final bool isNext;
  final bool isCurrent;

  const PrayerTimeModel({
    required this.type,
    required this.time,
    this.isNext = false,
    this.isCurrent = false,
  });

  PrayerTimeModel copyWith({
    PrayerType? type,
    DateTime? time,
    bool? isNext,
    bool? isCurrent,
  }) {
    return PrayerTimeModel(
      type: type ?? this.type,
      time: time ?? this.time,
      isNext: isNext ?? this.isNext,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }

  @override
  List<Object?> get props => [type, time, isNext, isCurrent];
}
