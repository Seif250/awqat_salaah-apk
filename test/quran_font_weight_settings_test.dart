import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awqat_salaah/features/quran/data/repositories/quran_repository.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_event.dart';
import 'package:awqat_salaah/features/quran/presentation/bloc/quran_state.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:awqat_salaah/features/settings/presentation/bloc/settings_event.dart';
import 'package:awqat_salaah/features/settings/presentation/pages/settings_page.dart';
import 'package:awqat_salaah/features/prayer_times/presentation/bloc/prayer_bloc.dart';
import 'package:awqat_salaah/services/prayer_calculation_service.dart';
import 'package:awqat_salaah/services/notification_service.dart';
import 'package:awqat_salaah/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late QuranRepository quranRepository;
  late QuranBloc quranBloc;
  late SettingsBloc settingsBloc;
  late PrayerBloc prayerBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService.withPrefs(prefs);
    quranRepository = QuranRepository(prefs);

    quranBloc = QuranBloc(repository: quranRepository)..add(const LoadQuranEvent());
    await quranBloc.stream.firstWhere((s) => s is QuranLoaded);
    settingsBloc = SettingsBloc(storageService: storageService)..add(const LoadSettingsEvent());
    prayerBloc = PrayerBloc(
      calculationService: PrayerCalculationService(),
      storageService: storageService,
      notificationService: NotificationService(),
    );
  });

  tearDown(() {
    quranBloc.close();
    settingsBloc.close();
    prayerBloc.close();
  });

  Widget buildSettingsWidget() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<QuranRepository>.value(value: quranRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<QuranBloc>.value(value: quranBloc),
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<PrayerBloc>.value(value: prayerBloc),
        ],
        child: const MaterialApp(
          home: SettingsPage(),
        ),
      ),
    );
  }

  testWidgets('SettingsPage renders سُمْك الرسم القرآني and allows selection', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildSettingsWidget());
    await tester.pumpAndSettle();

    // Verify initial tile presence and default subtitle (متوسط ٥٠٠)
    expect(find.text('سُمْك الرسم القرآني'), findsOneWidget);
    expect(find.text('متوسط (٥٠٠)'), findsOneWidget);

    // Tap to open selection dialog
    await tester.tap(find.text('سُمْك الرسم القرآني'));
    await tester.pumpAndSettle();

    // Verify dialog options
    expect(find.text('اختر سُمْك الرسم القرآني'), findsOneWidget);
    expect(find.text('عادي (٤٠٠)'), findsOneWidget);
    expect(find.text('متوسط (٥٠٠) - موصى به'), findsOneWidget);
    expect(find.text('عريض (٧٠٠)'), findsOneWidget);

    // Tap on عريض (٧٠٠)
    await tester.tap(find.text('عريض (٧٠٠)'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    // Dialog closed and tile updated to عريض (٧٠٠)
    expect(find.text('اختر سُمْك الرسم القرآني'), findsNothing);
    expect(find.text('عريض (٧٠٠)'), findsOneWidget);
    expect(quranRepository.getMushafFontWeight(), 700);

    // Tap again to switch to عادي (٤٠٠)
    await tester.tap(find.text('سُمْك الرسم القرآني'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('عادي (٤٠٠)'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('عادي (٤٠٠)'), findsOneWidget);
    expect(quranRepository.getMushafFontWeight(), 400);
  });
}
