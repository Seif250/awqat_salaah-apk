import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/storage_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final StorageService _storageService;

  SettingsBloc({required StorageService storageService})
      : _storageService = storageService,
        super(const SettingsState()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<ChangeCalculationMethodEvent>(_onChangeCalculationMethod);
    on<ChangeMadhabEvent>(_onChangeMadhab);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<ChangeNotificationOffsetEvent>(_onChangeNotificationOffset);
    on<ChangeThemeModeEvent>(_onChangeThemeMode);
    on<Toggle24HourFormatEvent>(_onToggle24HourFormat);
    on<UpdateAdjustmentsEvent>(_onUpdateAdjustments);
    on<UpdateIqamahOffsetsEvent>(_onUpdateIqamahOffsets);
  }

  void _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(SettingsState(
      calculationMethod: _storageService.calculationMethod,
      madhab: _storageService.madhab,
      notificationsEnabled: _storageService.notificationsEnabled,
      notificationOffsetMinutes: _storageService.notificationOffsetMinutes,
      themeMode: _storageService.themeMode,
      is24HourFormat: _storageService.is24HourFormat,
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
    ));
  }

  Future<void> _onChangeCalculationMethod(
    ChangeCalculationMethodEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setCalculationMethod(event.method);
    emit(state.copyWith(calculationMethod: event.method));
  }

  Future<void> _onChangeMadhab(
    ChangeMadhabEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setMadhab(event.madhab);
    emit(state.copyWith(madhab: event.madhab));
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setNotificationsEnabled(event.enabled);
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }

  Future<void> _onChangeNotificationOffset(
    ChangeNotificationOffsetEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setNotificationOffsetMinutes(event.offsetMinutes);
    emit(state.copyWith(notificationOffsetMinutes: event.offsetMinutes));
  }

  Future<void> _onChangeThemeMode(
    ChangeThemeModeEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setThemeMode(event.themeMode);
    emit(state.copyWith(themeMode: event.themeMode));
  }

  Future<void> _onToggle24HourFormat(
    Toggle24HourFormatEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setIs24HourFormat(event.is24Hour);
    emit(state.copyWith(is24HourFormat: event.is24Hour));
  }

  Future<void> _onUpdateAdjustments(
    UpdateAdjustmentsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setAdjustments(
      fajr: event.fajr,
      sunrise: event.sunrise,
      dhuhr: event.dhuhr,
      asr: event.asr,
      maghrib: event.maghrib,
      isha: event.isha,
    );
    emit(state.copyWith(
      adjustFajr: event.fajr,
      adjustSunrise: event.sunrise,
      adjustDhuhr: event.dhuhr,
      adjustAsr: event.asr,
      adjustMaghrib: event.maghrib,
      adjustIsha: event.isha,
    ));
  }

  Future<void> _onUpdateIqamahOffsets(
    UpdateIqamahOffsetsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    await _storageService.setIqamahOffsets(
      fajr: event.fajr,
      dhuhr: event.dhuhr,
      asr: event.asr,
      maghrib: event.maghrib,
      isha: event.isha,
    );
    emit(state.copyWith(
      iqamahFajr: event.fajr,
      iqamahDhuhr: event.dhuhr,
      iqamahAsr: event.asr,
      iqamahMaghrib: event.maghrib,
      iqamahIsha: event.isha,
    ));
  }
}
