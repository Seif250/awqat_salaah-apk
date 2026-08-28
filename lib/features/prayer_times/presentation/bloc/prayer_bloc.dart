import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/prayer_calculation_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/widget_service.dart';
import '../../../../services/notification_service.dart';
import 'prayer_event.dart';
import 'prayer_state.dart';

class PrayerBloc extends Bloc<PrayerEvent, PrayerState> {
  final PrayerCalculationService _calculationService;
  final StorageService _storageService;
  final NotificationService _notificationService;
  Timer? _timer;

  PrayerBloc({
    required PrayerCalculationService calculationService,
    required StorageService storageService,
    required NotificationService notificationService,
  })  : _calculationService = calculationService,
        _storageService = storageService,
        _notificationService = notificationService,
        super(const PrayerInitial()) {
    on<LoadPrayerTimesEvent>(_onLoadPrayerTimes);
    on<RefreshPrayerTimesEvent>(_onRefreshPrayerTimes);
    on<TimerTickEvent>(_onTimerTick);

    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const TimerTickEvent());
    });
  }

  Future<void> _onLoadPrayerTimes(
    LoadPrayerTimesEvent event,
    Emitter<PrayerState> emit,
  ) async {
    emit(const PrayerLoading());
    _calculateAndEmit(emit, rescheduleNotifications: true);
  }

  Future<void> _onRefreshPrayerTimes(
    RefreshPrayerTimesEvent event,
    Emitter<PrayerState> emit,
  ) async {
    _calculateAndEmit(emit, rescheduleNotifications: true);
  }

  void _calculateAndEmit(Emitter<PrayerState> emit, {bool rescheduleNotifications = false}) {
    try {
      final lat = _storageService.latitude;
      final lng = _storageService.longitude;
      final city = _storageService.cityName;
      final country = _storageService.countryName;
      final method = _storageService.calculationMethod;
      final madhab = _storageService.madhab;

      final now = DateTime.now();
      final prayerDay = _calculationService.calculatePrayerTimes(
        latitude: lat,
        longitude: lng,
        date: now,
        method: method,
        madhab: madhab,
        adjustFajr: _storageService.adjustFajr,
        adjustSunrise: _storageService.adjustSunrise,
        adjustDhuhr: _storageService.adjustDhuhr,
        adjustAsr: _storageService.adjustAsr,
        adjustMaghrib: _storageService.adjustMaghrib,
        adjustIsha: _storageService.adjustIsha,
        iqamahFajr: _storageService.iqamahFajr,
        iqamahDhuhr: _storageService.iqamahDhuhr,
        iqamahAsr: _storageService.iqamahAsr,
        iqamahMaghrib: _storageService.iqamahMaghrib,
        iqamahIsha: _storageService.iqamahIsha,
      );

      final remaining = prayerDay.targetTime.difference(now);

      emit(PrayerLoaded(
        prayerDay: prayerDay,
        remainingDuration: remaining.isNegative ? Duration.zero : remaining,
        cityName: city,
        countryName: country,
        lastCalculated: now,
      ));

      // Sync with Native Home Screen Widget
      WidgetService.updateHomeWidget(
        prayerDay: prayerDay,
        cityName: city,
        isArabic: true,
        is24Hour: _storageService.is24HourFormat,
      );

      // Schedule 7-day advance notifications when requested (e.g. app start, settings update, midnight)
      if (rescheduleNotifications) {
        _rescheduleWeeklyNotifications();
      }
    } catch (e) {
      emit(PrayerError(e.toString()));
    }
  }

  void _rescheduleWeeklyNotifications() {
    _notificationService.scheduleWeeklyPrayerNotifications(
      calculationService: _calculationService,
      latitude: _storageService.latitude,
      longitude: _storageService.longitude,
      method: _storageService.calculationMethod,
      madhab: _storageService.madhab,
      adjustFajr: _storageService.adjustFajr,
      adjustSunrise: _storageService.adjustSunrise,
      adjustDhuhr: _storageService.adjustDhuhr,
      adjustAsr: _storageService.adjustAsr,
      adjustMaghrib: _storageService.adjustMaghrib,
      adjustIsha: _storageService.adjustIsha,
      iqamahFajr: _storageService.iqamahFajr,
      iqamahDhuhr: _storageService.iqamahDhuhr,
      iqamahAsr: _storageService.iqamahAsr,
      iqamahMaghrib: _storageService.iqamahMaghrib,
      iqamahIsha: _storageService.iqamahIsha,
      isEnabled: _storageService.notificationsEnabled,
      isSoundEnabled: _storageService.notificationSoundEnabled,
      notificationOffsets: _storageService.notificationOffsets,
      isArabic: true,
      is24Hour: _storageService.is24HourFormat,
    );
  }

  void _onTimerTick(
    TimerTickEvent event,
    Emitter<PrayerState> emit,
  ) {
    if (state is PrayerLoaded) {
      final loaded = state as PrayerLoaded;
      final now = DateTime.now();
      final remaining = loaded.prayerDay.targetTime.difference(now);

      // If midnight passed, recalculate and roll forward weekly notifications
      if (now.day != loaded.lastCalculated.day) {
        _calculateAndEmit(emit, rescheduleNotifications: true);
      }
      // If target time reached (Adhan reached or Iqamah reached), transition phase
      // WITHOUT wiping pending scheduled alarms!
      else if (remaining.inSeconds <= 0) {
        _calculateAndEmit(emit, rescheduleNotifications: false);
      } else {
        emit(loaded.copyWith(remainingDuration: remaining));
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
