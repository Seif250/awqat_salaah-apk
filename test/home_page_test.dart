import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:awqat_salaah/core/constants/prayer_constants.dart';
import 'package:awqat_salaah/features/prayer_times/data/models/prayer_day_model.dart';
import 'package:awqat_salaah/features/prayer_times/data/models/prayer_time_model.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/bloc/prayer_bloc.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/bloc/prayer_state.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/pages/home_page.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_state.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_state.dart';
import 'package:awqat_salaah/features/azkar/presentation/bloc/azkar_bloc.dart';
import 'package:awqat_salaah/features/azkar/presentation/bloc/azkar_state.dart';

class FakePrayerBloc extends Cubit<PrayerState> implements PrayerBloc {
  FakePrayerBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQuranBloc extends Cubit<QuranState> implements QuranBloc {
  FakeQuranBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSettingsBloc extends Cubit<SettingsState> implements SettingsBloc {
  FakeSettingsBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAzkarBloc extends Cubit<AzkarState> implements AzkarBloc {
  FakeAzkarBloc(super.initialState);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  testWidgets('HomePage renders all redesigned sections with correct visual hierarchy', (tester) async {
    final now = DateTime(2026, 9, 25, 14, 30);
    final fajr = PrayerTimeModel(type: PrayerType.fajr, time: DateTime(2026, 9, 25, 4, 30));
    final sunrise = PrayerTimeModel(type: PrayerType.sunrise, time: DateTime(2026, 9, 25, 5, 50));
    final dhuhr = PrayerTimeModel(type: PrayerType.dhuhr, time: DateTime(2026, 9, 25, 12, 10));
    final asr = PrayerTimeModel(type: PrayerType.asr, time: DateTime(2026, 9, 25, 15, 30), isNext: true);
    final maghrib = PrayerTimeModel(type: PrayerType.maghrib, time: DateTime(2026, 9, 25, 18, 15));
    final isha = PrayerTimeModel(type: PrayerType.isha, time: DateTime(2026, 9, 25, 19, 45));

    final prayerDay = PrayerDayModel(
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
      timeRemaining: const Duration(hours: 1, minutes: 0),
    );

    final prayerBloc = FakePrayerBloc(
      PrayerLoaded(
        prayerDay: prayerDay,
        cityName: 'القاهرة',
        countryName: 'مصر',
        remainingDuration: const Duration(hours: 1, minutes: 0),
        lastCalculated: now,
      ),
    );
    final settingsBloc = FakeSettingsBloc(const SettingsState());
    final quranBloc = FakeQuranBloc(const QuranInitial());
    final azkarBloc = FakeAzkarBloc(const AzkarInitial());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PrayerBloc>.value(value: prayerBloc),
          BlocProvider<QuranBloc>.value(value: quranBloc),
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<AzkarBloc>.value(value: azkarBloc),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: HomePage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Header: 'وِرد' + 'صلاتك، قرآنك، ذكرك' + Settings icon
    expect(find.text('وِرد'), findsOneWidget);
    expect(find.text('صلاتك، قرآنك، ذكرك'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // 2. Compact Location: 'القاهرة، مصر'
    expect(find.text('القاهرة، مصر'), findsOneWidget);

    // 3. Level 1 Primary Hero: Next prayer card
    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('العصر'), findsWidgets); // on hero card and in prayer times strip

    // 4. Level 2: Quran continuation section
    expect(find.text('القرآن الكريم'), findsOneWidget);
    expect(find.text('فتح المصحف'), findsOneWidget);

    // 5. Level 2: Prayer times section
    expect(find.text('مواقيت الصلاة'), findsOneWidget);
    expect(find.text('عرض جميع المواقيت'), findsOneWidget);
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('الظهر'), findsOneWidget);
    expect(find.text('المغرب'), findsOneWidget);
    expect(find.text('العشاء'), findsOneWidget);

    // 6. Level 3: Quick Adhkar
    expect(find.text('الأذكار اليومية'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('أذكار المساء'), findsOneWidget);
    expect(find.text('أذكار النوم'), findsOneWidget);
    expect(find.text('التسبيح'), findsOneWidget);

    // 7. Level 3: Qibla utility
    expect(find.text('اتجاه القبلة'), findsOneWidget);

    // 8. Level 3: Daily Ayah
    expect(find.text('آية اليوم'), findsOneWidget);
    expect(find.text('﴿ أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ ﴾'), findsOneWidget);
    expect(find.text('سورة الرعد • الآية ٢٨'), findsOneWidget);
    expect(find.text('فتح السورة في المصحف'), findsOneWidget);
  });
}
