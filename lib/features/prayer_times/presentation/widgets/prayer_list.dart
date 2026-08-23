import 'package:flutter/material.dart';
import '../../data/models/prayer_day_model.dart';
import 'prayer_row.dart';

class PrayerList extends StatelessWidget {
  final PrayerDayModel prayerDay;
  final bool is24Hour;

  const PrayerList({
    super.key,
    required this.prayerDay,
    required this.is24Hour,
  });

  @override
  Widget build(BuildContext context) {
    final times = prayerDay.allTimes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'مواقيت اليوم',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 4),
        ...times.map((prayer) => PrayerRow(
              prayer: prayer,
              is24Hour: is24Hour,
            )),
      ],
    );
  }
}
