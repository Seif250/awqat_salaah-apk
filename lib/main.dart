import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'features/location/data/repositories/location_repository_impl.dart';
import 'services/notification_service.dart';
import 'services/prayer_calculation_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handler for Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 FlutterError: ${details.exceptionAsString()}');
  };

  // Custom error widget instead of red screen of death
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1410),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFD4AF37)),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ غير متوقع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kDebugMode ? details.exceptionAsString() : 'يرجى إعادة فتح التطبيق',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white70, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // Catch async errors that escape Flutter's framework
  runZonedGuarded(() async {
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
  }, (error, stackTrace) {
    debugPrint('🚨 Uncaught async error: $error\n$stackTrace');
  });
}
