import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awqat_salaah/core/theme/app_theme.dart';
import 'package:awqat_salaah/core/constants/prayer_constants.dart';
import 'package:awqat_salaah/features/prayer_times/data/models/prayer_day_model.dart';
import 'package:awqat_salaah/features/prayer_times/data/models/prayer_time_model.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/bloc/prayer_bloc.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/bloc/prayer_state.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/pages/prayer_times_page.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/widgets/next_prayer_card.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/widgets/prayer_row.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_state.dart';

class FakePrayerBloc extends Cubit<PrayerState> implements PrayerBloc {
  FakePrayerBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsBloc extends Cubit<SettingsState> implements SettingsBloc {
  FakeSettingsBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  late PrayerDayModel testPrayerDay;
  late FakePrayerBloc prayerBloc;
  late FakeSettingsBloc settingsBloc;

  setUp(() {
    final now = DateTime.now();
    final fajr = PrayerTimeModel(type: PrayerType.fajr, time: now.subtract(const Duration(hours: 10)), iqamahOffsetMinutes: 20);
    final sunrise = PrayerTimeModel(type: PrayerType.sunrise, time: now.subtract(const Duration(hours: 8)));
    final dhuhr = PrayerTimeModel(type: PrayerType.dhuhr, time: now.subtract(const Duration(hours: 2)), iqamahOffsetMinutes: 15);
    final asr = PrayerTimeModel(type: PrayerType.asr, time: now.add(const Duration(hours: 3)), iqamahOffsetMinutes: 15, isNext: true);
    final maghrib = PrayerTimeModel(type: PrayerType.maghrib, time: now.add(const Duration(hours: 5)), iqamahOffsetMinutes: 10);
    final isha = PrayerTimeModel(type: PrayerType.isha, time: now.add(const Duration(hours: 7)), iqamahOffsetMinutes: 15);

    testPrayerDay = PrayerDayModel(
      date: now,
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      phase: PrayerPhase.beforeAdhan,
      focusPrayerType: PrayerType.asr,
      targetTime: asr.time,
      timeRemaining: const Duration(hours: 3),
    );

    prayerBloc = FakePrayerBloc(
      PrayerLoaded(
        prayerDay: testPrayerDay,
        cityName: 'القاهرة',
        countryName: 'مصر',
        remainingDuration: const Duration(hours: 4, minutes: 12),
        lastCalculated: now,
      ),
    );

    settingsBloc = FakeSettingsBloc(
      const SettingsState(
        is24HourFormat: false,
        themeMode: ThemeMode.light,
      ),
    );
  });

  tearDown(() {
    prayerBloc.close();
    settingsBloc.close();
  });

  Widget buildTestableWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PrayerBloc>.value(value: prayerBloc),
        BlocProvider<SettingsBloc>.value(value: settingsBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: PrayerTimesPage(),
        ),
      ),
    );
  }

  group('PrayerTimesPage Redesign & Refinement Tests', () {
    testWidgets('Renders refined header with compact typography and actions', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Title
      expect(find.text('مواقيت الصلاة'), findsOneWidget);

      // Actions: Qibla & Settings
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('Renders compact dates and location in HeaderWidget', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // City and Country
      expect(find.textContaining('القاهرة، مصر'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('Renders Hero NextPrayerCard with correct visual hierarchy', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Next Prayer Card
      expect(find.byType(NextPrayerCard), findsOneWidget);
      expect(find.text('العصر'), findsWidgets); // on card and list
      expect(find.text('الصلاة القادمة'), findsWidgets);
      expect(find.textContaining('الأذان'), findsWidgets);
    });

    testWidgets('Renders unified schedule container for today\'s prayer times', (tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      // Section title
      expect(find.text('مواقيت اليوم'), findsOneWidget);

      // Six prayer rows rendered
      expect(find.byType(PrayerRow), findsNWidgets(6));

      // Prayers in order
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('الشروق'), findsOneWidget);
      expect(find.text('الظهر'), findsOneWidget);
      expect(find.text('المغرب'), findsOneWidget);
      expect(find.text('العشاء'), findsOneWidget);

      // Asr has 'القادمة' badge
      expect(find.text('القادمة'), findsOneWidget);

      // Dividers between rows in unified container
      expect(find.byType(Divider), findsNWidgets(5));
    });
  });
}
