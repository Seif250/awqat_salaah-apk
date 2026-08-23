import 'package:equatable/equatable.dart';
import '../../../../core/constants/prayer_constants.dart';

class PrayerTimeModel extends Equatable {
  final PrayerType type;
  final DateTime time;
  final bool isNext;
  final bool isCurrent;
  final int iqamahOffsetMinutes;

  const PrayerTimeModel({
    required this.type,
    required this.time,
    this.isNext = false,
    this.isCurrent = false,
    this.iqamahOffsetMinutes = 0,
  });

  DateTime? get iqamahTime =>
      type.isActualPrayer ? time.add(Duration(minutes: iqamahOffsetMinutes)) : null;

  bool isCurrentlyInIqamahWindow(DateTime now) {
    if (!type.isActualPrayer || iqamahTime == null) return false;
    return now.isAfter(time) && now.isBefore(iqamahTime!);
  }

  Duration? timeRemainingToIqamah(DateTime now) {
    if (!type.isActualPrayer || iqamahTime == null) return null;
    final diff = iqamahTime!.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  PrayerTimeModel copyWith({
    PrayerType? type,
    DateTime? time,
    bool? isNext,
    bool? isCurrent,
    int? iqamahOffsetMinutes,
  }) {
    return PrayerTimeModel(
      type: type ?? this.type,
      time: time ?? this.time,
      isNext: isNext ?? this.isNext,
      isCurrent: isCurrent ?? this.isCurrent,
      iqamahOffsetMinutes: iqamahOffsetMinutes ?? this.iqamahOffsetMinutes,
    );
  }

  @override
  List<Object?> get props => [type, time, isNext, isCurrent, iqamahOffsetMinutes];
}
