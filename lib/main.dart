import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'features/location/data/repositories/location_repository_impl.dart';
import 'services/notification_service.dart';
import 'services/prayer_calculation_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations & transparent status bar
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Core Services
  final storageService = await StorageService.init();
  final notificationService = NotificationService();
  await notificationService.init();
  final prayerCalculationService = PrayerCalculationService();
  final locationRepository = LocationRepository();

  runApp(
    AwqatSalaahApp(
      storageService: storageService,
      prayerCalculationService: prayerCalculationService,
      notificationService: notificationService,
      locationRepository: locationRepository,
    ),
  );
}
