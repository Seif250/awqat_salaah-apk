import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/core/constants/prayer_constants.dart';
import 'package:awqat_salaah/features/prayer_times/data/models/prayer_time_model.dart';
import 'package:awqat_salaah/features/prayer_times/data/models/prayer_day_model.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/widgets/prayer_row.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/widgets/next_prayer_card.dart';
import 'package:awqat_salaah/features/azkar/data/models/azkar_item_model.dart';
import 'package:awqat_salaah/features/azkar/presentation/widgets/azkar_card.dart';

void main() {
  group('UI Widget & Semantics Tests', () {
    testWidgets('PrayerRow renders prayer name, time, and accessible Semantics', (tester) async {
      final prayer = PrayerTimeModel(
        type: PrayerType.fajr,
        time: DateTime(2026, 8, 21, 4, 30),
        iqamahOffsetMinutes: 20,
        isNext: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrayerRow(
              prayer: prayer,
              is24Hour: false,
            ),
          ),
        ),
      );

      // Verify prayer name is visible
      expect(find.text('الفجر'), findsOneWidget);

      // Verify 'القادمة' badge is visible
      expect(find.text('القادمة'), findsOneWidget);

      // Verify semantics label contains prayer information
      final semanticsFinder = find.byType(Semantics);
      expect(semanticsFinder, findsWidgets);

      final semantics = tester.getSemantics(find.byType(PrayerRow));
      expect(semantics.label, contains('الفجر'));
      expect(semantics.label, contains('القادمة'));
    });

    testWidgets('NextPrayerCard displays prayer title and countdown', (tester) async {
      final now = DateTime(2026, 8, 21, 12, 0);
      final fajr = PrayerTimeModel(type: PrayerType.fajr, time: DateTime(2026, 8, 21, 4, 30));
      final sunrise = PrayerTimeModel(type: PrayerType.sunrise, time: DateTime(2026, 8, 21, 6, 0));
      final dhuhr = PrayerTimeModel(
        type: PrayerType.dhuhr,
        time: DateTime(2026, 8, 21, 12, 30),
        iqamahOffsetMinutes: 15,
        isNext: true,
      );
      final asr = PrayerTimeModel(type: PrayerType.asr, time: DateTime(2026, 8, 21, 15, 45));
      final maghrib = PrayerTimeModel(type: PrayerType.maghrib, time: DateTime(2026, 8, 21, 18, 30));
      final isha = PrayerTimeModel(type: PrayerType.isha, time: DateTime(2026, 8, 21, 19, 50));

      final prayerDay = PrayerDayModel(
        date: now,
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        phase: PrayerPhase.beforeAdhan,
        focusPrayerType: PrayerType.dhuhr,
        targetTime: dhuhr.time,
        timeRemaining: const Duration(minutes: 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextPrayerCard(
              prayerDay: prayerDay,
              remainingDuration: const Duration(minutes: 30),
              is24Hour: false,
            ),
          ),
        ),
      );

      expect(find.text('الظهر'), findsOneWidget);
      expect(find.text('الصلاة القادمة'), findsOneWidget);
    });

    testWidgets('AzkarCard increments count on tap and shows progress', (tester) async {
      int incrementCount = 0;
      bool isCompleted = false;

      const item = AzkarItem(
        id: 'test_zikr',
        title: 'سبحان الله وبحمده',
        arabicText: 'سبحان الله وبحمده عدد خلقه',
        targetCount: 33,
        currentCount: 10,
        category: AzkarCategory.morning,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AzkarCard(
              item: item,
              onIncrement: () => incrementCount++,
              onToggleComplete: () => isCompleted = !isCompleted,
            ),
          ),
        ),
      );

      expect(find.text('سبحان الله وبحمده'), findsOneWidget);
      expect(find.text('10/33'), findsOneWidget);

      // Tap card to increment
      await tester.tap(find.text('سبحان الله وبحمده'));
      await tester.pump();

      expect(incrementCount, equals(1));
    });
  });
}
