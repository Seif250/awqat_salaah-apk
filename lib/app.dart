import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/azkar/data/repositories/azkar_repository.dart';
import 'features/azkar/presentation/bloc/azkar_bloc.dart';
import 'features/azkar/presentation/bloc/azkar_event.dart';
import 'features/quran/data/repositories/quran_repository.dart';
import 'features/quran/presentation/bloc/quran_bloc.dart';
import 'features/quran/presentation/bloc/quran_event.dart';
import 'features/location/data/repositories/location_repository_impl.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/prayer_times/presentation/bloc/prayer_bloc.dart';
import 'features/prayer_times/presentation/bloc/prayer_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'services/notification_service.dart';
import 'services/prayer_calculation_service.dart';
import 'services/storage_service.dart';

class AwqatSalaahApp extends StatelessWidget {
  final StorageService storageService;
  final PrayerCalculationService prayerCalculationService;
  final NotificationService notificationService;
  final LocationRepository locationRepository;

  const AwqatSalaahApp({
    super.key,
    required this.storageService,
    required this.prayerCalculationService,
    required this.notificationService,
    required this.locationRepository,
  });

  @override
  Widget build(BuildContext context) {
    final azkarRepository = AzkarRepository(storageService.prefs);
    final quranRepository = QuranRepository(storageService.prefs);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AzkarRepository>.value(value: azkarRepository),
        RepositoryProvider<QuranRepository>.value(value: quranRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>(
            create: (_) => SettingsBloc(
              storageService: storageService,
            )..add(const LoadSettingsEvent()),
          ),
          BlocProvider<LocationBloc>(
            create: (_) => LocationBloc(
              locationRepository: locationRepository,
              storageService: storageService,
            ),
          ),
          BlocProvider<PrayerBloc>(
            create: (_) => PrayerBloc(
              calculationService: prayerCalculationService,
              storageService: storageService,
              notificationService: notificationService,
            )..add(const LoadPrayerTimesEvent()),
          ),
          BlocProvider<AzkarBloc>(
            create: (_) => AzkarBloc(
              repository: azkarRepository,
            )..add(const LoadAzkarEvent()),
          ),
          BlocProvider<QuranBloc>(
            create: (_) => QuranBloc(
              repository: quranRepository,
            )..add(const LoadQuranEvent()),
          ),
        ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            locale: const Locale('ar'),
            supportedLocales: const [
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SplashPage(storageService: storageService),
          );
        },
      ),
      ),
    );
  }
}
